# frozen_string_literal: true

require_relative 'routes_refine/mounting'

module Flame
	class Router
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

			using GorillaPatch::Namespace

			def initialize(
				namespace_name, controller_or_name, path, nested: true, &block
			)
				@controller =
					ControllerFinder.new(namespace_name, controller_or_name).controller
				@namespace_name = @controller.deconstantize
				@path = Flame::Path.new(path || @controller.path)
				@routes, @endpoint = @path.to_routes_with_endpoint
				@reverse_routes = {}
				@mount_nested = nested
				execute(&block)
			end

			private

			HTTP_METHODS.each do |http_method|
				## Define refine methods for all HTTP methods
				## @overload post(path, action)
				##   Execute action on requested path and HTTP method
				##   @param path [String] path of method for the request
				##   @param action [Symbol] name of method for the request
				##   @example
				##     Set path to '/bye' and method to :POST for action `goodbye`
				##       post '/bye', :goodbye
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
					get action unless find_reverse_route(action)
				end

				mount_nested_controllers if @mount_nested
			end

			## Assign methods of the controller to REST architecture
			def rest
				self.class.rest_routes.each do |rest_route|
					action = rest_route[:action]
					if !@controller.actions.include?(action) || find_reverse_route(action)
						next
					end

					send(*rest_route.values.map(&:downcase))
				end
			end

			include Mounting

			## Execute block of refinings end sorting routes
			def execute(&block)
				@controller.refined_http_methods
					.each do |action, (http_method, action_path)|
						send(http_method, action_path, action)
					end
				instance_exec(&block) if block
				defaults
			end

			def find_reverse_route(action)
				@reverse_routes.dig(@controller.to_s, action)
			end

			def validate_action_path(action, action_path)
				Validators::RouteArgumentsValidator
					.new(@controller, action_path, action)
					.valid?
			end

			def remove_old_routes(action, new_route)
				old_path = @reverse_routes[@controller.to_s]&.delete(action)
				return unless old_path

				@routes.dig(*old_path.parts)
					.delete_if { |_method, old_route| old_route == new_route }
			end

			using GorillaPatch::DeepMerge

			def add_new_route(route, action, path, http_method)
				path_routes, endpoint = path.to_routes_with_endpoint
				endpoint[http_method] = route
				@routes.deep_merge!(path_routes)
				(@reverse_routes[@controller.to_s] ||= {})[action] = path
			end
		end
	end
end
