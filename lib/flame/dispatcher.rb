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

		def initialize(app, env)
			@app = app
			@env = env
			@request = Flame::Request.new(env)
			@response = Flame::Response.new
		end

		def run!
			catch :halt do
				try_route ||
				  try_static ||
				  try_static(File.join(__dir__, '..', '..', 'public')) ||
				  try_error(404)
			end
			response.write body
			response.finish
		end

		def status(value = nil)
			response.status ||= 200
			response.headers['X-Cascade'] = 'pass' if value == 404
			value ? response.status = value : response.status
		end

		def body(value = nil)
			value ? @body = value : @body
		end

		def params
			@params ||= request.params.merge(request.params.keys_to_sym)
		end

		def session
			request.session
		end

		def cookies
			@cookies ||= Cookies.new(request.cookies, response)
		end

		def config
			@app.config
		end

		def path_to(ctrl, action = :index, args = {})
			route = @app.class.router.find_route(controller: ctrl, action: action)
			fail RouteNotFoundError.new(ctrl, action) unless route
			path = route.assign_arguments(args)
			path.empty? ? '/' : path
		end

		def halt(new_status = nil, new_body = nil, new_headers = {})
			case new_status
			when String then new_body = new_status
			when Integer then status new_status
			end
			# new_status.is_a?(String) ? () : (status new_status)
			new_body = default_body if new_body.nil? && body.empty?
			body new_body if new_body
			response.headers.merge!(new_headers)
			throw :halt
		end

		private

		## Generate default body of error page
		def default_body
			return if Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.include?(status)
			response.headers[Rack::CONTENT_TYPE] = 'text/html'
			"<h1>#{Rack::Utils::HTTP_STATUS_CODES[status]}</h1>"
		end

		## Find nearest route
		def nearest_route_for_request
			@app.router.find_nearest_route(request.path_parts)
		end

		## Find route and try execute it
		def try_route
			route = @app.class.router.find_route(
				method: request.http_method,
				path_parts: request.path_parts
			)
			return nil unless route
			status 200
			params.merge!(route.arguments(request.path_parts))
			# route.execute(self)
			execute_route(route)
		end

		def execute_route(route)
			exec_route = route.executable
			exec_route.run!(self)
		rescue => exception
			dump_error(exception)
			# status 500
			# exec_route.execute_errors(status)
			try_error(500, exec_route)
		end

		def try_error(error_status = nil, exec_route = nil)
			status error_status if error_status
			unless exec_route
				route = nearest_route_for_request unless exec_route
				exec_route = route.executable if route
			end
			exec_route.execute_errors(status) if exec_route
			halt
		end

		def dump_error(error)
			msg = [
				"#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - " \
				"#{error.class} - #{error.message}:",
				*error.backtrace
			].join("\n\t")
			@env['rack.errors'].puts(msg)
		end
	end
end
