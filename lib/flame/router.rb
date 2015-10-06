require_relative './route.rb'
require_relative './validators.rb'

module Flame
	## Router class for routing
	class Router
		attr_accessor :routes

		def initialize
			@routes = []
		end

		def add_controller(ctrl, path, block = nil)
			## TODO: Add Regexp paths
			## TODO: Add `before` and `after` methods

			## Add routes from controller to glob array
			ctrl_routes = RouteRefine.new(ctrl, path, block).routes
			ActionsValidator.new(ctrl_routes, ctrl).valid?
			routes.concat(ctrl_routes)
		end

		## Find route by any attributes
		def find_route(attrs)
			routes.find { |route| route.compare_attributes(attrs) }
		end

		private

		## Helper module for routing refine
		class RouteRefine
			attr_reader :routes

			def self.http_methods
				[:GET, :POST, :PUT, :DELETE]
			end

			def rest_routes
				[
					{ method: :GET,     path: '/',  action: :index  },
					{ method: :POST,    path: '/',  action: :create },
					{ method: :GET,     path: '/',  action: :show   },
					{ method: :PUT,     path: '/',  action: :update },
					{ method: :DELETE,  path: '/',  action: :delete }
				]
			end

			def initialize(ctrl, path, block)
				@ctrl = ctrl
				@path = path || default_controller_path
				@routes = []
				block.nil? ? defaults : instance_exec(&block)
				# p @routes
				@routes.sort! { |a, b| b[:path] <=> a[:path] }
			end

			http_methods.each do |request_method|
				define_method(request_method.downcase) do |path, action|
					ArgumentsValidator.new(@ctrl, path, action).valid?
					add_route(request_method, path, action)
				end
			end

			def defaults
				@ctrl.public_instance_methods(false).each do |action|
					next if find_route_index(action: action)
					add_route(:GET, nil, action)
				end
			end

			def rest
				rest_routes.each do |rest_route|
					action = rest_route[:action]
					if @ctrl.public_instance_methods.include?(action) &&
					   find_route_index(action: action).nil?
						add_route(*rest_route.values, true)
					end
				end
			end

			private

			using GorillaPatch::StringExt

			def default_controller_path
				@ctrl.name.underscore
				  .split('_')
				  .take_while { |part| part != 'controller' }
				  .unshift(nil)
				  .join('/')
			end

			def make_path(path, action = nil, force_params = false)
				## TODO: Add :arg:type support (:id:num, :name:str, etc.)
				unshifted = force_params ? path : action_path(action)
				if path.nil? || force_params
					path = @ctrl.instance_method(action).parameters
					       .map { |par| ":#{par[0] == :req ? '' : '?'}#{par[1]}" }
					       .unshift(unshifted)
					       .join('/')
				end
				"#{@path}/#{path}".gsub(%r{\/{2,}}, '/')
			end

			def action_path(action)
				action == :index ? '/' : action
			end

			def add_route(method, path, action, force_params = false)
				route = Route.new(
					method: method,
					path: make_path(path, action, force_params),
					controller: @ctrl,
					action: action
				)
				index = find_route_index(action: action)
				index ? @routes[index] = route : @routes.push(route)
			end

			def find_route_index(attrs)
				@routes.find_index { |route| route.compare_attributes(attrs) }
			end
		end
	end
end
