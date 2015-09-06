require_relative './_render'

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

		## TODO: Add more helpers
	end
end
