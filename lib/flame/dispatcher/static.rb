# frozen_string_literal: true

module Flame
	class Dispatcher
		## Module for working with static files
		module Static
			def find_static(filename = request.path_info, dir: config[:public_dir])
				StaticFile.new(filename, dir)
			end

			private

			## Find static files and try return it
			def try_static(*args)
				file = find_static(*args)
				return nil unless file.exist?
				return_static(file)
			end

			def return_static(file)
				halt 304 if file.newer? request.env['HTTP_IF_MODIFIED_SINCE']
				response.content_type = file.extname
				response[Rack::CACHE_CONTROL] = 'no-cache'
				response['Last-Modified'] = file.mtime.httpdate
				body file.content
			end

			## Class for static files with helpers methods
			class StaticFile
				def initialize(filename, dir)
					@filename = filename.to_s
					@path = File.join dir, URI.decode(@filename)
				end

				def exist?
					File.exist?(@path) && File.file?(@path)
				end

				def mtime
					File.mtime(@path)
				end

				def extname
					File.extname(@path)
				end

				def newer?(http_since)
					http_since && Time.httpdate(http_since).to_i >= mtime.to_i
				end

				def content
					File.read(@path)
				end

				def path(with_version: false)
					path = @filename
					with_version ? "#{path}?v=#{mtime.to_i}" : path
				end
			end
		end
	end
end
