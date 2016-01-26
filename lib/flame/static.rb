module Flame
	class Dispatcher
		## Module for working with static files
		module Static
			## Find static files and try return it
			def try_static(dir = config[:public_dir])
				file = File.join(dir, request.path_info)
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
		end
	end
end
