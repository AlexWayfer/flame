require 'rack'
require_relative 'request'

module Flame
	## Class initialize when Application.call(env) invoked
	## For new request and response
	class Dispatcher
		def initialize(app, env)
			@app = app
			@env = env
		end

		def run!
			body = catch :halt do
				try_route ||
				try_static ||
				try_static(File.join(__dir__, '..', '..', 'public')) ||
				halt(404)
			end
			response.write body
			response.finish
		end

		## Helpers
		def config
			@app.config
		end

		def router
			@app.router
		end

		def request
			@request ||= Flame::Request.new(@env)
		end

		def params
			request.params
		end

		def response
			@response ||= Rack::Response.new
		end

		def status(value = nil)
			response.status ||= 200
			value ? response.status = value : response.status
		end

		def halt(new_status, body = '', new_headers = {})
			status new_status
			response.headers.merge!(new_headers)
			# p response.body
			if body.empty? &&
			   !Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.include?(status)
				body = Rack::Utils::HTTP_STATUS_CODES[status]
			end
			throw :halt, body
		end

		def path_to(ctrl, action, args = {})
			route = @app.router.find_route(controller: ctrl, action: action)
			fail RouteNotFoundError.new(ctrl, action) unless route
			path = route.assign_arguments(args)
			path.empty? ? '/' : path
		end

		def redirect(*params)
			throw :halt, response.redirect(
				params[0].is_a?(String) ? params[0] : path_to(*params)
			)
		end

		def session
			request.session
		end

		def cookies
			@cookies ||= Cookies.new(request.cookies, response)
		end

		private

		def try_route
			method = params['_method'] || request.request_method
			route = @app.router.find_route(
				method: method,
				path_parts: request.path_parts
			)
			# p route
			return nil unless route
			status 200
			route.execute(self)
		end

		def try_static(dir = config[:public_dir])
			static_file = File.join(dir, request.path_info)
			# p static_file
			return nil unless File.exist?(static_file) && File.file?(static_file)
			return_static(static_file)
		end

		def return_static(file)
			since = @env['HTTP_IF_MODIFIED_SINCE']
			file_time = File.mtime(file)
			halt 304 if since && Time.httpdate(since).to_i >= file_time.to_i
			response.headers.merge!(
				'Content-Type' => file_mime_type(file),
				'Last-Modified' => file_time.httpdate
				# 'Content-Disposition' => 'attachment;' \
				#	"filename=\"#{File.basename(static_file)}\"",
				# 'Content-Length' => File.size?(static_file).to_s
			)
			halt 200, File.read(file)
		end

		def file_mime_type(file)
			Rack::Mime.mime_type(File.extname(file))
		end

		## Helper class for cookies
		class Cookies
			def initialize(request_cookies, response)
				@request_cookies = request_cookies
				@response = response
			end

			def [](key)
				@request_cookies[key] || @request_cookies[key.to_s]
			end

			def []=(key, new_value)
				return @response.delete_cookie(key) if new_value.nil?
				@response.set_cookie(key, value: new_value, path: '/')
			end
		end
	end
end
