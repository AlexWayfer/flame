require_relative './validators.rb'

module Flame
	## Router class for routing
	class Router
		attr_accessor :routes

		def initialize
			@routes = []
		end

		def add_controller(ctrl, path, block)
			## TODO: Add `rest` method
			## TODO: Add Regexp paths
			## TODO: More defaults arguments

			## Add routes from controller to glob array
			ctrl_routes = RouteRefine.new(ctrl, path, block).routes
			ActionsValidator.new(ctrl_routes, ctrl).valid?
			routes.concat(ctrl_routes)
		end

		## Find block of code for routing
		def find_route(request_method, request_path)
			# p routes
			result_route = routes.find do |route|
				@args = {}
				next unless compare_methods(request_method, route[:method])
				compare_paths(request_path, route[:path])
			end
			return nil if result_route.nil?
			arrange_arguments(result_route.merge(args: @args))
		end

		private

		## Helper module for routing refine
		class RouteRefine
			attr_reader :routes

			def initialize(ctrl, path, block)
				@ctrl = ctrl
				@path = path
				@routes = []
				instance_exec(&block)
			end

			[:GET, :POST, :PUT, :DELETE].each do |request_method|
				define_method(request_method.downcase) do |path, action|
					ArgumentsValidator.new(@ctrl, path, action).valid?
					add_route(request_method, path, action)
				end
			end

			def defaults
				@ctrl.public_instance_methods(false).each do |action|
					next if route_index(action)
					add_route(:GET, nil, action)
				end
			end

			private

			def make_path(path, action = nil)
				if path.nil?
					path = @ctrl.instance_method(action).parameters
					       .select { |par| par[0] == :req }
					       .map { |par| ":#{par[1]}" }
					       .unshift(action == :index ? '/' : action)
					       .join('/')
				end
				"#{@path}/#{path}".gsub('//', '/')
			end

			def add_route(method, path, action)
				route = {
					method: method,
					path: make_path(path, action),
					controller: @ctrl,
					action: action
				}
				index = route_index(action)
				index ? @routes[index] = route : @routes.push(route)
			end

			def route_index(action)
				@routes.find_index { |route| route[:action] == action }
			end
		end

		def arrange_arguments(route)
			route[:arranged_args] =
				route[:controller].instance_method(route[:action]).parameters
				.map! { |par| par[1] }
				.each_with_object([]) { |par, arr| arr << route[:args][par] }
			route
		end

		def compare_methods(request_method, route_method)
			request_method.upcase.to_sym == route_method.upcase.to_sym
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
