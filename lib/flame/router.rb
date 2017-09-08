# frozen_string_literal: true

require 'gorilla-patch/deep_merge'
require 'gorilla-patch/inflections'
require 'gorilla-patch/namespace'

require_relative 'router/routes'
require_relative 'router/route'

module Flame
	## Router class for routing
	class Router
		attr_reader :app, :routes, :reverse_routes

		## @param app [Flame::Application] host application
		def initialize(app)
			@app = app
			@routes = Flame::Router::Routes.new
			@reverse_routes = {}
		end

		## Find the nearest route by path
		## @param path [Flame::Path] path for route finding
		## @return [Flame::Route, nil] return the found nearest route or `nil`
		def find_nearest_route(path)
			path_parts = path.parts.dup
			loop do
				route = routes.endpoint(*path_parts)&.values&.grep(Route)&.first
				break route if route || path_parts.pop.nil?
			end
		end

		## Find the path of route
		## @param route_or_controller [Flame::Router::Route, Flame::Controller]
		##   route or controller
		## @param action [Symbol, nil] action (or not for route)
		## @return [Flame::Path] mounted path to action of controller
		def path_of(route_or_controller, action = nil)
			if route_or_controller.is_a?(Flame::Router::Route)
				route = route_or_controller
				controller = route.controller
				action = route.action
			else
				controller = route_or_controller
			end
			reverse_routes.dig(controller.to_s, action)
		end

		## Helper class for controller routing refine
		class RoutesRefine
			attr_reader :routes, :reverse_routes

			## Defaults REST routes (methods, pathes, controllers actions)
			def self.rest_routes
				@rest_routes ||= [
					{ method: :GET,     path: '/',  action: :index  },
					{ method: :POST,    path: '/',  action: :create },
					{ method: :GET,     path: '/',  action: :show   },
					{ method: :PUT,     path: '/',  action: :update },
					{ method: :DELETE,  path: '/',  action: :delete }
				]
			end

			def initialize(router, namespace_name, controller_name, path, &block)
				@router = router
				@controller = constantize_controller namespace_name, controller_name
				@path = Flame::Path.new(path || @controller.default_path)
				@routes, @endpoint = @path.to_routes_with_endpoint
				@reverse_routes = {}
				execute(&block)
			end

			private

			using GorillaPatch::Inflections

			def constantize_controller(namespace_name, controller_name)
				controller_name = controller_name.to_s.camelize
				namespace =
					namespace_name.empty? ? Object : Object.const_get(namespace_name)
				if namespace.const_defined?(controller_name)
					controller = namespace.const_get(controller_name)
					return controller if controller < Flame::Controller
					controller::IndexController
				else
					namespace.const_get("#{controller_name}Controller")
				end
			end

			%i[GET POST PUT PATCH DELETE].each do |http_method|
				## Define refine methods for all HTTP methods
				## @overload post(path, action)
				##   Execute action on requested path and HTTP method
				##   @param path [String] path of method for the request
				##   @param action [Symbol] name of method for the request
				##   @example Set path to '/bye' and method to :POST for action `goodbye`
				##     post '/bye', :goodbye
				## @overload post(action)
				##   Execute action on requested HTTP method
				##   @param action [Symbol] name of method for the request
				##   @example Set method to :POST for action `goodbye`
				##     post :goodbye
				define_method(http_method.downcase) do |action_path, action = nil|
					## Swap arguments if action in path variable
					unless action
						action = action_path.to_sym
						action_path = nil
					end
					## Initialize new route
					route = Route.new(@controller, action)
					## Make path by controller method with parameners
					action_path = Flame::Path.new(action_path).adapt(@controller, action)
					## Validate action path
					validate_action_path(action, action_path)
					## Merge action path with controller path
					path = Flame::Path.new(@path, action_path)
					## Remove the same route if needed
					remove_old_routes(action, route)
					## Add new route
					add_new_route(route, action, path, http_method)
				end
			end

			## Assign remaining methods of the controller
			##   to defaults pathes and HTTP methods
			def defaults
				rest
				@controller.actions.each do |action|
					next if find_reverse_route(action)
					send(:GET.downcase, action)
				end
			end

			## Assign methods of the controller to REST architecture
			def rest
				self.class.rest_routes.each do |rest_route|
					action = rest_route[:action]
					next if !@controller.actions.include?(action) ||
					        find_reverse_route(action)
					send(*rest_route.values.map(&:downcase))
				end
			end

			using GorillaPatch::Namespace
			using GorillaPatch::DeepMerge

			## Mount controller inside other (parent) controller
			## @param controller [Flame::Controller] class of mounting controller
			## @param path [String, nil] root path for mounting controller
			## @yield Block of code for routes refine
			def mount(controller_name, path = nil, &block)
				routes_refine = self.class.new(
					@router, @controller.deconstantize, controller_name, path, &block
				)

				@endpoint.deep_merge! routes_refine.routes

				@reverse_routes.merge!(
					routes_refine.reverse_routes.transform_values do |hash|
						hash.transform_values { |action_path| @path + action_path }
					end
				)
			end

			# private

			## Execute block of refinings end sorting routes
			def execute(&block)
				instance_exec(&block) if block
				defaults
			end

			def find_reverse_route(action)
				@reverse_routes.dig(@controller.to_s, action)
			end

			def validate_action_path(action, action_path)
				Validators::RouteArgumentsValidator.new(
					@controller, action_path, action
				).valid?
			end

			def remove_old_routes(action, new_route)
				return unless (old_path = @reverse_routes[@controller.to_s]&.delete(action))
				@routes.dig(*old_path.parts)
					.delete_if { |_method, old_route| old_route == new_route }
			end

			def add_new_route(route, action, path, http_method)
				path_routes, endpoint = path.to_routes_with_endpoint
				endpoint[http_method] = route
				@routes.deep_merge!(path_routes)
				(@reverse_routes[@controller.to_s] ||= {})[action] = path
			end
		end
	end
end
