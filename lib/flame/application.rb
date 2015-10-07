require_relative './router'
require_relative './dispatcher'

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

		def self.inherited(app)
			root_dir = File.dirname(caller[0].split(':')[0])
			app.config.merge!(
				root_dir: root_dir,
				public_dir: File.join(root_dir, 'public'),
				views_dir: File.join(root_dir, 'views')
			)
		end

		## Init function
		def call(env)
			Dispatcher.new(self, env).run!
		end

		def self.mount(ctrl, path = nil, &block)
			router.add_controller(ctrl, path, block)
		end

		## Router for routing
		def self.router
			@router ||= Flame::Router.new
		end

		def router
			self.class.router
		end
	end
end
