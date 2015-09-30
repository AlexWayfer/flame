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
			route = self.class.router.find_route(request_method, request.path_info)
			if route
				body = route_execute(route)
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

		def route_execute(route)
			ctrl = route[:controller].new(self)
			status 200
			params.merge!(route[:args])
			ctrl.send(route[:action], *route[:arranged_args])
		end
	end
end
