require_relative './render'

module Flame
	## Class for controllers helpers, like Framework::Controller
	class Controller
		include Flame::Render

		def initialize(app)
			@app = app
		end

		def config
			@app.config
		end

		def params
			@app.params
		end

		def path_to(ctrl, method, args = {})
			path = @app.class.router.find_path(ctrl, method)
			assign_arguments_to_path(path, args)
		end

		## TODO: Add more helpers

		private

		def assign_arguments_to_path(path, args = {})
			path_parts = path.split('/')
			path_parts.map! do |path_part|
				assign_argument_to_path_part(path, path_part, args)
			end
			path_parts.unshift('').join('/').gsub(%r{\/{2,}}, '/')
		end

		def assign_argument_to_path_part(path, path_part, args = {})
			## Not argument
			return path_part unless path_part[0] == ':'
			## Not required argument
			return args[path_part[2..-1].to_sym] if path_part[1] == '?'
			## Required argument
			param = args[path_part[1..-1].to_sym]
			## Required argument is nil
			fail ArgumentNotAssigned.new(path, path_part) if param.nil?
			## All is ok
			param
		end
	end
end
