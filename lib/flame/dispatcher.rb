module Flame
	## Helpers for dispatch Flame::Application#call
	module Dispatcher
		def dispatch
			body = catch :halt do
				try_route ||
				try_static ||
				try_static(File.join(__dir__, '..', '..', 'public')) ||
				halt(404)
			end
			response.write body
			response.finish
		end

		## Find route and try execute it
		def try_route
			route = self.class.router.find_route(
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
			route[:afters].each do |after|
				result = ctrl.send(after, result)
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
			response.headers.merge!(
				'Content-Type' => Rack::Mime.mime_type(File.extname(file)),
				'Last-Modified' => file_time.httpdate
				# 'Content-Disposition' => 'attachment;' \
				#	"filename=\"#{File.basename(static_file)}\"",
				# 'Content-Length' => File.size?(static_file).to_s
			)
			halt 200, File.read(file)
		end
	end
end
