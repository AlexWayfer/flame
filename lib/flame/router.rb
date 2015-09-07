module Flame
	## Router class for routing
	class Router
		def add_controller(ctrl, path, block)
			# ctrl.instance_methods(false).each do |action|
				# parameters = ctrl.instance_method(action).parameters
				# route_path = path
				# route_path += "/#{action}" unless action == :index
				# parameters.each do |parameter|
				# 	route_path += "/:#{parameter[1]}" if parameter[0] == :req
				# end
				# route_path.gsub!('//', '/') unless route_path == '/'
				# routes << {
				# 	method: :GET,
				# 	path: route_path,
				# 	controller: ctrl,
				# 	action: action
				# }
			# end

			## TODO: Add `rest` and `defaults` methods
			## TODO: Add Regexp paths
			## TODO: More defaults values

			## Add routes from controller to glob array
			ctrl_routes = RouteRefine.new(ctrl, path, block).routes
			routes.concat(ctrl_routes)
			compare_actions(
				ctrl_routes.map { |route| route[:action] },
				ctrl
			)
		end

		## Find block of code for routing
		def find_route(request_method, request_path)
			# p routes
			result_route = routes.find do |route|
				@args = {}
				next unless request_method.upcase.to_sym == route[:method]
				compare_paths(request_path, route[:path])
			end
			result_route.merge(args: @args) if result_route.is_a?(Hash)
		end

	private

		## If no mount actions or no owned by controller
		def compare_actions(routes_actions, ctrl)
			ctrl_actions = ctrl.instance_methods(false)
			extra_routes_actions = routes_actions - ctrl_actions
			fail "#{ctrl} doesn't have methods:"\
				 " #{extra_routes_actions.join(', ')}" if extra_routes_actions.any?
			extra_ctrl_actions = ctrl_actions - routes_actions
			fail "#{ctrl}'s actions doesn't refine:" \
				 " #{extra_ctrl_actions.join(', ')}" if extra_ctrl_actions.any?
		end

		## Helper module for routing refine
		class RouteRefine
			attr_reader :routes

			def initialize(ctrl, path, block)
				@ctrl = ctrl
				@path = path
				@routes = []
				instance_exec(&block)
			end

			## TODO: Replace to define_method
			[:GET, :POST, :PUT, :DELETE].each do |request_method|
				define_method(request_method.downcase) do |path, action|
					arguments_valid?(path, action)
					# route_path.gsub!('//', '/') unless route_path == '/'
					@routes << {
						method: request_method,
						path: "#{@path}/#{path}".gsub!('//', '/'),
						controller: @ctrl,
						action: action
					}
				end
			end

		private

			## Split path to args array
			def path_arguments(path)
				args = path.split('/').select { |part| part[0] == ':' }
				args.map { |arg| arg[1..-1].to_sym }
			end

			## Take args from controller's action
			def action_arguments(action)
				parameters = @ctrl.instance_method(action).parameters
				req_parameters = parameters.select { |par| par[0] == :req }
				{
					all: parameters.map { |par| par[1] },
					req: req_parameters.map { |par| par[1] }
				}
			end

			## Compare arguments from path and from controller's action
			def arguments_valid?(path, action)
				## Break path for ':arg' arguments
				path_args = path_arguments(path)
				## Take all and required arguments from Ctrl#action
				action_args = action_arguments(action)
				## Subtraction action args from path args
				extra_path_args = path_args - action_args[:all]
				fail "#{@ctrl}##{action} doesn't know arguments" \
					 " from path '#{path}':" \
					 " #{extra_path_args.join(', ')}" if extra_path_args.any?
				## Subtraction path args from action required args
				extra_action_args = action_args[:req] - path_args
				fail "Path '#{path}' doesn't content" \
				     " #{@ctrl}##{action}'s required arguments:" \
					 " #{extra_action_args.join(', ')}" if extra_action_args.any?
			end
		end

		## Helpers functions for variables
		def self.routes
			@routes ||= []
		end
		def routes
			self.class.routes
		end

		## Helpers for finding route
		def compare_paths(request_path, route_path)
			case route_path.class
			when Regexp
				request_path =~ route_path
			else
				path_parts = route_path.to_s.split('/').reject(&:empty?)
				request_parts = request_path.split('/').reject(&:empty?)
				return false if request_parts.count != path_parts.count
				compare_parts(request_parts, path_parts)
			end
		end

		def compare_parts(request_parts, path_parts)
			request_parts.each_with_index do |request_part, i|
				path_part = path_parts[i]
				break false unless path_part
				if path_part[0] == ':'
					@args[path_part[1..-1].to_sym] = URI.decode(request_part)
					next
				end
				break false unless request_part == path_part
			end
		end
	end
end
