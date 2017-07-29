# frozen_string_literal: true

require 'gorilla-patch/deep_merge'
require 'gorilla-patch/dig_empty'

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

		using GorillaPatch::DeepMerge

		## Add the controller with it's methods to routes
		## @param ctrl [Flame::Controller] class of the controller which will be added
		## @param path [String, nil] root path for controller's methods
		## @yield block for routes refine
		def add_controller(ctrl, path = nil, &block)
			## @todo Add Regexp paths

			## Add routes from controller to glob array
			routes_refine = RoutesRefine.new(self, ctrl, path, block)

			routes.deep_merge!(routes_refine.routes)
			reverse_routes.merge!(routes_refine.reverse_routes)
		end

		using GorillaPatch::DigEmpty

		## Find route by any attributes
		## @param path [Flame::Path, String] path for route search
		## @param http_method [Symbol, nil] HTTP-method
		## @return [Flame::Route, nil] return the found route, otherwise `nil`
		def find_route(path, http_method = nil)
			path = Flame::Path.new(path) unless path.is_a?(Flame::Path)
			endpoint = routes.dig(*path.parts)&.dig_through_opt_args
			return unless endpoint
			http_method = :GET if http_method == :HEAD
			## For `find_nearest_route` with any method
			route = http_method ? endpoint[http_method] : endpoint.values.first
			route if route.is_a? Flame::Router::Route
		end

		## Find the nearest route by path
		## @param path [Flame::Path] path for route finding
		## @return [Flame::Route, nil] return the found nearest route or `nil`
		def find_nearest_route(path)
			path = Flame::Path.new(path) if path.is_a? String
			path_parts = path.parts.dup
			while path_parts.size >= 0
				route = find_route Flame::Path.new(*path_parts)
				break if route || path_parts.empty?
				path_parts.pop
			end
			route.is_a?(Flame::Router::Routes) ? route[nil] : route
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
			attr_accessor :rest_routes
			attr_reader :ctrl, :routes, :reverse_routes

			## Defaults REST routes (methods, pathes, controllers actions)
			def rest_routes
				@rest_routes ||= [
					{ method: :GET,     path: '/',  action: :index  },
					{ method: :POST,    path: '/',  action: :create },
					{ method: :GET,     path: '/',  action: :show   },
					{ method: :PUT,     path: '/',  action: :update },
					{ method: :DELETE,  path: '/',  action: :delete }
				]
			end

			def initialize(router, ctrl, path, block)
				@router = router
				@ctrl = ctrl
				@path = path || @ctrl.default_path
				@routes = Flame::Router::Routes.new
				@reverse_routes = {}
				execute(&block)
			end

			private

			using GorillaPatch::DeepMerge
			using GorillaPatch::DigEmpty

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
					route = Route.new(@ctrl, action)
					## Make path by controller method with parameners
					action_path = Flame::Path.new(action_path).adapt(@ctrl, action)
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
				@ctrl.actions.each do |action|
					next if find_reverse_route(action)
					send(:GET.downcase, action)
				end
			end

			## Assign methods of the controller to REST architecture
			def rest
				rest_routes.each do |rest_route|
					action = rest_route[:action]
					next if !@ctrl.actions.include?(action) ||
					        find_reverse_route(action)
					send(*rest_route.values.map(&:downcase))
				end
			end

			## Mount controller inside other (parent) controller
			## @param ctrl [Flame::Controller] class of mounting controller
			## @param path [String, nil] root path for mounting controller
			## @yield Block of code for routes refine
			def mount(ctrl, path = nil, &block)
				path = Flame::Path.merge(@path, path || ctrl.default_path)
				@router.add_controller(ctrl, path, &block)
			end

			# private

			## Execute block of refinings end sorting routes
			def execute(&block)
				instance_exec(&block) if block
				defaults
			end

			def find_reverse_route(action)
				@reverse_routes.dig(@ctrl.to_s, action)
			end

			def validate_action_path(action, action_path)
				Validators::RouteArgumentsValidator.new(
					@ctrl, action_path, action
				).valid?
			end

			def remove_old_routes(action, new_route)
				return unless (old_path = @reverse_routes[@ctrl.to_s]&.delete(action))
				@routes.dig(*old_path.parts)
					.delete_if { |_method, old_route| old_route == new_route }
			end

			def add_new_route(route, action, path, http_method)
				path_routes, endpoint = path.to_routes_with_endpoint
				endpoint[http_method] = route
				@routes.deep_merge!(path_routes)
				(@reverse_routes[@ctrl.to_s] ||= {})[action] = path
			end
		end

		private_constant :RoutesRefine
	end
end
