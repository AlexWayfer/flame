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

		## TODO: Add 'path_to' helper
		## TODO: Add more helpers
	end
end
