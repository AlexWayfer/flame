# frozen_string_literal: true

require 'forwardable'
require_relative 'render'

module Flame
	## Class initialize when Dispatcher found route with it
	## For new request and response
	class Controller
		extend Forwardable

		## Shortcut for not-inherited public methods: actions
		def self.actions
			public_instance_methods(false)
		end

		def_delegators(
			:@dispatcher,
			:config, :request, :params, :halt, :session, :response, :status, :body,
			:default_body, :cached_tilts
		)

		## Initialize the controller for request execution
		## @param dispatcher [Flame::Dispatcher] dispatcher object
		def initialize(dispatcher)
			@dispatcher = dispatcher
		end

		## Helpers
		def path_to(*args)
			add_controller_class(args)
			@dispatcher.path_to(*args)
		end

		## Build a URI to the given controller and action, or path
		def url_to(*args)
			path = args.first.is_a?(String) ? args.first : path_to(*args)
			"#{request.scheme}://#{request.host_with_port}#{path}"
		end

		## Redirect for response
		## @overload redirect(path, status)
		##   Redirect to the string path
		##   @param path [String] path
		##   @param status [Ingeter, nil] HTTP status
		##   @return [nil]
		##   @example Redirect to '/hello'
		##     redirect '/hello'
		##   @example Redirect to '/hello' with status 301
		##     redirect '/hello', 301
		## @overload redirect(uri, status)
		##   Redirect to the URI location
		##   @param uri [URI] URI object
		##   @param status [Ingeter, nil] HTTP status
		##   @return [nil]
		##   @example Redirect to 'http://example.com'
		##     redirect URI::HTTP.build(host: 'example.com')
		##   @example Redirect to 'http://example.com' with status 301
		##     redirect URI::HTTP.build(host: 'example.com'), 301
		## @overload redirect(*args, status)
		##   Redirect to the path of `path_to` method
		##   @param args arguments for `path_to` method
		##   @param status [Ingeter, nil] HTTP status
		##   @return [nil]
		##   @example Redirect to `show` method of `ArticlesController` with id = 2
		##     redirect ArticlesController, :show, id: 2
		##   @example Redirect to method of controller with status 301
		##     redirect ArticlesController, :show, { id: 2 }, 301
		def redirect(*args)
			args[0] = args.first.to_s if args.first.is_a? URI
			unless args.first.is_a? String
				path_to_args_range = 0..(args.last.is_a?(Integer) ? -2 : -1)
				args[path_to_args_range] = path_to(*args[path_to_args_range])
			end
			response.redirect(*args)
			nil
		end

		## Set the Content-Disposition to "attachment" with the specified filename,
		## instructing the user agents to prompt to save,
		## and set Content-Type by filename.
		## @param filename [String, nil] filename of attachment
		## @param disposition [Symbol, String] main content for Content-Disposition
		## @example Set Content-Disposition header without filename
		##   attachment
		## @example Set Content-Disposition header with filename and Content-Type
		##   attachment 'style.css'
		def attachment(filename = nil, disposition = :attachment)
			content_dis = 'Content-Disposition'
			response[content_dis] = disposition.to_s
			return unless filename
			response[content_dis] << "; filename=\"#{File.basename(filename)}\""
			ext = File.extname(filename)
			response.content_type = ext unless ext.empty?
		end

		## Render a template with `Flame::Render` (based on Tilt-engine)
		## @param path [Symbol, nil] path to the template file
		## @param options [Hash] options for the `Flame::Render` rendering
		## @return [String] rendered template
		def view(path = nil, options = {})
			cache = options.delete(:cache)
			cache = config[:environment] == 'production' if cache.nil?
			template = Flame::Render.new(
				self,
				(path || caller_locations(1, 1)[0].label.to_sym),
				options
			)
			template.render(cache: cache)
		end
		alias render view

		protected

		## Execute the method of the controller with hooks (may be overloaded)
		## @param method [Symbol] name of the controller method
		def execute(method)
			# send method
			body send(method, *extract_params_for(method).values)
		end

		## Default method for Internal Server Error, can be inherited
		def server_error(_exception)
			body default_body
		end

		private

		## Execute any action from any controller
		## @example Execute `new` action of `ArticlesController`
		##   reroute ArticlesController, :new
		## @example Execute `index` action of `ArticlesController`
		##   reroute ArticlesController
		## @example Execute `foo` action of current controller
		##   reroute :foo
		def reroute(*args)
			add_controller_class(args)
			ctrl, action = args[0..1]
			ctrl_object = ctrl == self.class ? self : ctrl.new(@dispatcher)
			ctrl_object.send :execute, action
		end

		def extract_params_for(action)
			# p action, params, parameters
			method(action).parameters.each_with_object({}) do |parameter, result|
				key = parameter.last
				next if params[key].nil?
				result[key] = params[key]
			end
		end

		def add_controller_class(args)
			args.unshift(self.class) if args[0].is_a?(Symbol)
			args.insert(1, :index) if args[0].is_a?(Class) && !args[1].is_a?(Symbol)
		end

		class << self
			using GorillaPatch::Inflections

			## Default root path of the controller for requests
			def default_path
				modules = underscore.split('/')
				parts = modules.pop.split('_')
				parts.shift if parts.first == 'index'
				parts.pop if %w[controller ctrl].include? parts.last
				parts = [modules.last] if parts.empty?
				Flame::Path.merge nil, parts.join('_')
			end

			## Re-define public instance method from parent
			## @example Inherit controller with parent actions by method
			##   class MyController < BaseController.with_actions
			##   end
			def with_actions
				@with_actions ||= Class.new(self) { extend ParentActions }
			end
		end

		## Module for public instance methods re-defining from superclass
		## @example Inherit controller with parent actions by `extend`
		##   class MyController < BaseController
		##     extend Flame::Controller::ParentActions
		##   end
		module ParentActions
			def inherited(ctrl)
				ctrl.define_parent_actions
			end

			def self.extended(ctrl)
				ctrl.define_parent_actions
			end

			def define_parent_actions
				superclass.actions.each do |public_method|
					um = superclass.public_instance_method(public_method)
					define_method public_method, um
				end
			end
		end
	end
end
