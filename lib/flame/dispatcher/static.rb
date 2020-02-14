# frozen_string_literal: true

require 'cgi'

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
			def try_static(*args, **kwargs)
				file = find_static(*args, **kwargs)
				return nil unless file.exist?

				halt 400 unless file.within_directory
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
				attr_reader :extname, :within_directory

				def initialize(filename, dir)
					@filename = filename.to_s
					@directory = File.expand_path dir
					@file_path = File.expand_path File.join dir, CGI.unescape(@filename)
					@extname = File.extname(@file_path)
					@within_directory = @file_path.start_with? @directory
				end

				def exist?
					File.exist?(@file_path) && File.file?(@file_path)
				end

				def mtime
					File.mtime(@file_path)
				end

				def newer?(http_since)
					!http_since || mtime.to_i > Time.httpdate(http_since).to_i
				end

				def content
					File.read(@file_path)
				end

				def path(with_version: false)
					with_version ? "#{@filename}?v=#{mtime.to_i}" : @filename
				end
			end

			private_constant :StaticFile
		end
	end
end
