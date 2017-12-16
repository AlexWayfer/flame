# frozen_string_literal: true

module Flame
	class Dispatcher
		## Module for working with static files
		module Static
			## Find static file by path
			## @param filename [String] relative path to the static file
			## @param dir [String]
			##   absolute local path of the directory with static files
			## @return [Flame::Dispatcher::Static::StaticFile] instance of static file
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
				response[Rack::CACHE_CONTROL] = 'public, max-age=31536000' # one year
				halt 304 unless file.newer? request.env['HTTP_IF_MODIFIED_SINCE']
				response.content_type = file.extname
				response['Last-Modified'] = file.mtime.httpdate
				body file.content
			end

			## Class for static files with helpers methods
			class StaticFile
				def initialize(filename, dir)
					@filename = filename.to_s
					@file_path = File.join dir, URI.decode_www_form_component(@filename)
				end

				def exist?
					File.exist?(@file_path) && File.file?(@file_path)
				end

				def mtime
					File.mtime(@file_path)
				end

				def extname
					File.extname(@file_path)
				end

				def newer?(http_since)
					!http_since || mtime.to_i > Time.httpdate(http_since).to_i
				end

				def content
					File.read(@file_path)
				end

				def path(with_version: false)
					path = @filename
					with_version ? "#{path}?v=#{mtime.to_i}" : path
				end
			end

			private_constant :StaticFile
		end
	end
end
