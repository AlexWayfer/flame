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

		def path_to(ctrl, action, args = {})
			route = @app.class.router.find_route(controller: ctrl, action: action)
			fail RouteNotFoundError.new(ctrl, action) unless route
			route.assign_arguments(args)
		end

		## TODO: Add more helpers
	end
end
