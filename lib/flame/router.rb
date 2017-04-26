# frozen_string_literal: true

require_relative 'route'

module Flame
	## Router class for routing
	class Router
		attr_reader :app, :routes

		def initialize(app)
			@app = app
			@routes = []
		end

		## Add the controller with it's methods to routes
		## @param ctrl [Flame::Controller] class of the controller which will be added
		## @param path [String, nil] root path for controller's methods
		## @yield block for routes refine
		def add_controller(ctrl, path = nil, &block)
			## @todo Add Regexp paths

			## Add routes from controller to glob array
			route_refine = RouteRefine.new(self, ctrl, path, block)
			concat_routes(route_refine)
		end

		## Find route by any attributes
		## @param attrs [Hash] attributes for comparing
		## @return [Flame::Route, nil] return the found route, otherwise `nil`
		def find_route(attrs)
			route = routes.find { |r| r.compare_attributes(attrs) }
			route.dup if route
		end

		## Find the nearest route by path parts
		## @param path_parts [Array] parts of path for route finding
		## @return [Flame::Route, nil] return the found nearest route, otherwise `nil`
		def find_nearest_route(path_parts)
			while path_parts.size >= 0
				route = find_route(path_parts: path_parts)
				break if route || path_parts.empty?
				path_parts.pop
			end
			route
		end

		private

		## Add `RouteRefine` routes to the routes of `Flame::Router`
		## @param route_refine [Flame::Router::RouteRefine] `RouteRefine` with routes
		def concat_routes(route_refine)
			routes.concat(route_refine.routes)
		end

		## Helper class for controller routing refine
		class RouteRefine
			attr_accessor :rest_routes
			attr_reader :ctrl, :routes

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
				@routes = []
				execute(&block)
			end

			%i[GET POST PUT PATCH DELETE].each do |request_method|
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
				method = request_method.downcase
				define_method(method) do |path, action = nil, prefix: false|
					## Swap arguments if action in path variable
					unless action
						action = path.to_sym
						path = nil
					end
					## Make path by controller method with parameners
					path = default_action_path(action, path) if prefix || path.nil?
					## Merge action path with controller path
					self_path = path
					path = Route.path_merge(@path, path)
					route = Route.new(@ctrl, action, method, path, self_path)
					index = find_route_index(action: action)
					index ? @routes[index] = route : @routes.push(route)
				end
			end

			## Assign remaining methods of the controller
			##   to defaults pathes and HTTP methods
			def defaults
				rest
				@ctrl.actions.each do |action|
					next if find_route_index(action: action)
					send(:GET.downcase, action)
				end
			end

			## Assign methods of the controller to REST architecture
			def rest
				rest_routes.each do |rest_route|
					action = rest_route[:action]
					next if !@ctrl.actions.include?(action) ||
					        find_route_index(action: action)
					send(*rest_route.values.map(&:downcase), prefix: true)
				end
			end

			## Mount controller inside other (parent) controller
			## @param ctrl [Flame::Controller] class of mounting controller
			## @param path [String, nil] root path for mounting controller
			## @yield Block of code for routes refine
			def mount(ctrl, path = nil, &block)
				path = Route.path_merge(@path, path || ctrl.default_path)
				@router.add_controller(ctrl, path, &block)
			end

			private

			## Execute block of refinings end sorting routes
			def execute(&block)
				instance_exec(&block) if block
				defaults
				@routes.sort!
			end

			def find_route_index(attrs)
				@routes.find_index { |route| route.compare_attributes(attrs) }
			end

			## Build path for the action of controller
			## @todo Add :arg:type support (:id:num, :name:str, etc.)
			def default_action_path(action, prefix)
				unshifted = prefix ? prefix : action_prefix(action)
				parameters = @ctrl.instance_method(action).parameters
				parameters.map! do |par|
					":#{par[0] == :req ? '' : ARG_CHAR_OPT}#{par[1]}"
				end
				Route.path_merge(parameters.unshift(unshifted))
			end

			def action_prefix(action)
				action == :index ? '/' : action
			end
		end
	end
end
