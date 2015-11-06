require 'rack'
require_relative 'request'
require_relative 'render'

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
			route = router.find_route(controller: ctrl, action: action)
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

		def view(path, options = {})
			Flame::Render.new(self, path, options).render
		end
		alias_method :render, :view

		private

		def try_route
			route = router.find_route(
				method: request.http_method,
				path_parts: request.path_parts
			)
			# p route
			return nil unless route
			status 200
			params.merge!(route.arguments(request.path_parts))
			# route.execute(self)
			execute_route(route)
		end

		def execute_route(route)
			singleton_class.include route[:controller]
			router.find_befores(route).each { |before| send(before) }
			result = send(route[:action], *route.arranged_params(params))
			router.find_afters(route).each do |after|
				result = send(after, result)
			end
			result
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
				@request_cookies[key.to_s]
			end

			def []=(key, new_value)
				return @response.delete_cookie(key.to_s, path: '/') if new_value.nil?
				@response.set_cookie(key.to_s, value: new_value, path: '/')
			end
		end
	end
end
