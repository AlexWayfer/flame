# frozen_string_literal: true

require 'forwardable'
require 'gorilla-patch/namespace'

require_relative 'controller/with_actions'
require_relative 'render'

module Flame
	## Class initialize when Dispatcher found route with it
	## For new request and response
	class Controller
		extend Forwardable

		FORBIDDEN_ACTIONS = [].freeze

		## Shortcut for not-inherited public methods: actions
		## @return [Array<Symbol>] array of actions (public instance methods)
		def self.actions
			public_instance_methods(false)
		end

		def_delegators(
			:@dispatcher,
			:config, :request, :params, :halt, :session, :response, :status, :body,
			:default_body, :cached_tilts, :find_static
		)

		## Initialize the controller for request execution
		## @param dispatcher [Flame::Dispatcher] host dispatcher
		def initialize(dispatcher)
			@dispatcher = dispatcher
		end

		## Look documentation at {Flame::Dispatcher#path_to}
		def path_to(*args)
			add_controller_class(args)
			@dispatcher.path_to(*args)
		end

		## Build a URI to the given controller and action, or path
		def url_to(*args, **options)
			first_arg = args.first
			path =
				if first_arg.is_a?(String) || first_arg.is_a?(Flame::Path)
					find_static(first_arg).path(with_version: options[:version])
				else
					path_to(*args, **options)
				end
			Addressable::URI.new(
				scheme: request.scheme, host: request.host_with_port, path: path
			).to_s
		end

		using GorillaPatch::Namespace

		## Path to previous page, or to index action, or to Index controller
		## @return [String] path to previous page or to index
		def path_to_back
			back_path = request.referer
			return back_path if back_path && back_path != request.url
			return path_to :index if self.class.actions.include?(:index)
			'/'
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
			status
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
			body send(method, *extract_params_for(method))
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
			body
		end

		def extract_params_for(action)
			## Take parameters from action method
			parameters = method(action).parameters
			## Fill variables with values from params
			req_values, opt_values = %i[req opt].map! do |type|
				params.values_at(
					*parameters.select { |key, _value| key == type }.map!(&:last)
				)
			end
			## Remove nils from the end of optional values
			opt_values.pop while opt_values.last.nil? && !opt_values.empty?
			## Concat values
			req_values + opt_values
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
		end
	end
end
