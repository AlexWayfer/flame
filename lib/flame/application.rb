require_relative 'router'
require_relative 'dispatcher'

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

		def initialize
			app = self
			@builder = Rack::Builder.new do
				app.class.middlewares.each { |m| use m[:class], *m[:args], &m[:block] }
				run app
			end
		end

		## Init function
		def call(env)
			if env[:FLAME_CALL]
				Dispatcher.new(self, env).run!
			else
				env[:FLAME_CALL] = true
				@builder.call env
			end
		end

		def self.mount(ctrl, path = nil, &block)
			router.add_controller(ctrl, path, block)
		end

		def self.use(middleware, *args, &block)
			middlewares << { class: middleware, args: args, block: block }
		end

		def self.middlewares
			@middlewares ||= []
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
