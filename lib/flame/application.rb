require_relative './request'
require_relative './router'

module Flame
	## Core class, like Framework::Application
	class Application
		## Framework configuration
		def self.config
			@config ||= {}
		end

		def config
			self.class.config
		end

		include Flame::Request

		def self.inherited(app)
			app.config[:root_dir] = File.dirname(caller[0].split(':')[0])
			app.config[:views_dir] = File.join(app.config[:root_dir], 'views')
		end

		## Init function
		def call(env)
			new_request(env)
			request_method = params['_method'] || request.request_method
			route = router.find_route(method: request_method, path: request.path_info)
			if route
				status 200
				body = route.execute(self)
				[status, headers, [body]]
			else
				[404, {}, ['Not Found']]
			end
		end

		def self.mount(ctrl, path = nil, &block)
			router.add_controller(ctrl, path, block)
		end

		private

		## Router for routing
		def self.router
			@router ||= Flame::Router.new
		end

		def router
			self.class.router
		end
	end
end
