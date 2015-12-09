require 'gorilla-patch/hash'

module Flame
	## Helpers for dispatch Flame::Application#call
	class Dispatcher
		attr_reader :request, :response

		using GorillaPatch::HashExt

		def initialize(app, env)
			@app = app
			@request = Flame::Request.new(env)
			@response = Rack::Response.new
		end

		def run!
			body = catch :halt do
				try_route ||
				try_static ||
				try_static(File.join(__dir__, '..', '..', 'public')) ||
				halt(404)
			end
			# p body
			response.write body
			response.finish
		end

		def status(value = nil)
			response.status ||= 200
			value ? response.status = value : response.status
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

		def halt(new_status, body = nil, new_headers = {})
			new_status.is_a?(String) ? (body = new_status) : (status new_status)
			response.headers.merge!(new_headers)
			# p response.body
			if body.nil? &&
			   !Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.include?(status)
				body = Rack::Utils::HTTP_STATUS_CODES[status]
			end
			throw :halt, body
		end

		private

		## Find route and try execute it
		def try_route
			route = @app.class.router.find_route(
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
			ctrl = route[:controller].new(self)
			route[:befores].each { |before| ctrl.send(before) }
			result = ctrl.send(route[:action], *route.arranged_params(params))
			route[:afters].each { |after| result = execute_after(ctrl, after, result) }
			result
		end

		def execute_after(ctrl, after, result)
			case after.class.to_s.to_sym
			when :Symbol, :String
				result = ctrl.send(after.to_sym, result)
			when :Proc
				ctrl.instance_exec(result, &after)
			else
				fail UnexpectedTypeOfAfterError.new(after, route)
			end
			result
		end

		## Find static files and try return it
		def try_static(dir = config[:public_dir])
			file = File.join(dir, request.path_info)
			# p static_file
			return nil unless File.exist?(file) && File.file?(file)
			return_static(file)
		end

		def static_cached?(file_time)
			since = request.env['HTTP_IF_MODIFIED_SINCE']
			since && Time.httpdate(since).to_i >= file_time.to_i
		end

		def return_static(file)
			file_time = File.mtime(file)
			halt 304 if static_cached?(file_time)
			mime_type = Rack::Mime.mime_type(File.extname(file))
			response.headers.merge!(
				'Content-Type' => mime_type,
				'Last-Modified' => file_time.httpdate
				# 'Content-Disposition' => 'attachment;' \
				#	"filename=\"#{File.basename(static_file)}\"",
				# 'Content-Length' => File.size?(static_file).to_s
			)
			halt 200, File.read(file)
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
