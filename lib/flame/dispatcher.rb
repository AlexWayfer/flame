require 'gorilla-patch/hash'

require_relative 'cookies'
require_relative 'request'
require_relative 'response'
require_relative 'static'

module Flame
	## Helpers for dispatch Flame::Application#call
	class Dispatcher
		attr_reader :request, :response

		using GorillaPatch::HashExt

		include Flame::Dispatcher::Static

		## Initialize Dispatcher from Application#call
		## @param app [Flame::Application] application object
		## @param env Rack-environment object
		def initialize(app, env)
			@app = app
			@env = env
			@request = Flame::Request.new(env)
			@response = Flame::Response.new
		end

		## Start of execution the request
		def run!
			catch :halt do
				try_route ||
				  try_static ||
				  try_static(File.join(__dir__, '..', '..', 'public')) ||
				  not_found
			end
			response.write body
			response.finish
		end

		## Acccess to the status of response
		## @param value [Ineger, nil] integer value for new status
		## @return [Integer] current status
		## @example Set status value
		##   status 200
		def status(value = nil)
			response.status ||= 200
			response.headers['X-Cascade'] = 'pass' if value == 404
			value ? response.status = value : response.status
		end

		## Acccess to the body of response
		## @param value [String, nil] string value for new body
		## @return [String] current body
		## @example Set body value
		##   body 'Hello World!'
		def body(value = nil)
			value ? @body = value : @body ||= ''
		end

		## Parameters of the request
		def params
			@params ||= request.params.merge(request.params.keys_to_sym(deep: true))
		end

		## Session object as Hash
		def session
			request.session
		end

		## Cookies object as Hash
		def cookies
			@cookies ||= Cookies.new(request.cookies, response)
		end

		## Application-config object as Hash
		def config
			@app.config
		end

		## Access to Content-Type header of response
		def content_type(ext = nil)
			return response[Rack::CONTENT_TYPE] unless ext
			response[Rack::CONTENT_TYPE] = Rack::Mime.mime_type(ext)
		end

		## Get path for controller and action.
		##
		## @param ctrl [Flame::Controller] class of controller
		## @param action [Symbol] method of controller
		## @param args [Hash] parameters for method of controller
		## @return [String] path for requested method, controller and parameters
		## @example Path for `show(id)` method of `ArticlesController` with `id: 2`
		##   path_to ArticlesController, :show, id: 2 # => "/articles/show/2"
		def path_to(ctrl, action = :index, args = {})
			route = @app.class.router.find_route(controller: ctrl, action: action)
			raise Errors::RouteNotFoundError.new(ctrl, action) unless route
			path = route.assign_arguments(args)
			path.empty? ? '/' : path
		end

		## Interrupt the execution of route, and set new optional data
		##   (otherwise using existing)
		## @param new_status_or_body [Integer, String]
		##   set new HTTP status code or new body
		## @param new_body [String] set new body
		## @param new_headers [String] merge new headers
		## @example Halt with 500, no change body
		##   halt 500
		## @example Halt with 404, render template
		##   halt 404, render('errors/404')
		## @example Halt with 200, set new headers
		##   halt 200, 'Cats!', 'Content-Type' => 'animal/cat'
		def halt(new_status_or_body = nil, new_body = nil, new_headers = {})
			case new_status_or_body
			when String then new_body = new_status_or_body
			when Integer then status new_status_or_body
			end
			# new_status.is_a?(String) ? () : (status new_status)
			new_body = default_body if new_body.nil? && body.empty?
			body new_body if new_body
			response.headers.merge!(new_headers)
			throw :halt
		end

		## Add error's backtrace to @env['rack.errors'] (terminal or file)
		## @param error [Exception] exception for class, message and backtrace
		def dump_error(error)
			@error_message = [
				"#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - " \
				"#{error.class} - #{error.message}:",
				*error.backtrace
			].join("\n\t")
			@env['rack.errors'].puts(@error_message)
		end

		private

		## Generate default body of error page
		def default_body
			## Return nil if must be no body for current HTTP status
			return if Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.include?(status)
			response.headers[Rack::CONTENT_TYPE] = 'text/html'
			"<h1>#{Rack::Utils::HTTP_STATUS_CODES[status]}</h1>"
		end

		## Find route and try execute it
		def try_route
			route = @app.class.router.find_route(
				method: request.http_method,
				path_parts: request.path_parts
			)
			return nil unless route
			execute_route(route)
		end

		## Execute route
		## @param route [Flame::Route] route that must be executed
		def execute_route(route)
			status 200
			params.merge!(route.arguments(request.path_parts))
			# route.execute(self)
			route_exec(route)
		rescue => exception
			# p 'rescue from dispatcher'
			dump_error(exception) unless @error_message
			halt 500

			# p 're raise exception from dispatcher'
			# raise exception
		end

		## Generate a response if the route is not found
		def not_found
			# p 'not found from dispatcher'
			## Change the status of response to 404
			status 404
			## Find the nearest route by the parts of requested path
			route = @app.router.find_nearest_route(request.path_parts)
			## Halt with default body if the route not found
			##   or it's `not_found` method not defined
			return halt unless route && route.controller.method_defined?(:not_found)
			## Execute `not_found` method for the founded route
			route_exec(route, :not_found)
		end

		## Create controller object and execute method
		def route_exec(route, method = nil)
			method ||= route.action
			route.controller.new(self).send(:execute, method)
		end
	end
end
