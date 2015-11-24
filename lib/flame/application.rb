require_relative 'router'
require_relative 'request'
require_relative 'dispatcher'

module Flame
	## Core class, like Framework::Application
	class Application
		class << self
			attr_accessor :config
			attr_reader :middlewares
		end

		include Flame::Dispatcher

		## Framework configuration
		def config
			self.class.config
		end

		def request(env = nil)
			env ? @request = Flame::Request.new(env) : @request
		end

		def params
			request.params
		end

		def self.inherited(app)
			root_dir = File.dirname(caller[0].split(':')[0])
			app.config = {
				root_dir: root_dir,
				public_dir: File.join(root_dir, 'public'),
				views_dir: File.join(root_dir, 'views'),
				config_dir: File.join(root_dir, 'config')
			}
			app.use Rack::Session::Pool
		end

		def initialize
			app = self
			@builder = Rack::Builder.new do
				(app.class.middlewares || []).each do |m|
					use m[:class], *m[:args], &m[:block]
				end
				run app
			end
		end

		## Init function
		def call(env)
			if env[:FLAME_CALL]
				request(env) && response(true)
				dispatch
			else
				env[:FLAME_CALL] = true
				@builder.call env
			end
		end

		def response(init = false)
			init ? @response = Rack::Response.new : @response
		end

		def status(value = nil)
			response.status ||= 200
			value ? response.status = value : response.status
		end

		def halt(new_status, body = '', new_headers = {})
			status new_status
			response.headers.merge!(new_headers)
			# p response.body
			if body.empty? &&
			   !Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.include?(status)
				body = Rack::Utils::HTTP_STATUS_CODES[status]
			end
			throw :halt, body
		end

		def path_to(ctrl, action, args = {})
			route = self.class.router.find_route(controller: ctrl, action: action)
			fail RouteNotFoundError.new(ctrl, action) unless route
			path = route.assign_arguments(args)
			path.empty? ? '/' : path
		end

		def self.mount(ctrl, path = nil, &block)
			router.add_controller(ctrl, path, block)
		end

		def self.use(middleware, *args, &block)
			(@middlewares ||= []) << { class: middleware, args: args, block: block }
		end

		## Router for routing
		def self.router
			@router ||= Flame::Router.new
		end
	end
end
