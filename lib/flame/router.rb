require_relative './validators.rb'

module Flame
	## Router class for routing
	class Router
		attr_accessor :routes

		def initialize
			@routes = []
		end

		def add_controller(ctrl, path, block)
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
			# p @args
			add_arguments(result_route)
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
				@path = path
				@routes = []
				instance_exec(&block)
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
					next if route_index(action)
					add_route(:GET, nil, action)
				end
			end

			def rest
				rest_routes.each do |route|
					action = route[:action]
					if @ctrl.public_instance_methods.include?(action) &&
					   route_index(action).nil?
						add_route(*route.values, true)
					end
				end
			end

			private

			def make_path(path, action = nil, force_params = false)
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
				route = {
					method: method,
					path: make_path(path, action, force_params),
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
			route[:controller].instance_method(route[:action]).parameters
			  .each_with_object([]) do |par, arr|
				  arr << route[:args][par[1]] if par[0] == :req || route[:args][par[1]]
			  end
		end

		def add_arguments(route)
			route = route.merge(args: @args)
			route[:arranged_args] = arrange_arguments(route)
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
				# p route_path
				req_path_parts = path_parts.select { |part| part[1] != '?' }
				return false if request_parts.count < req_path_parts.count
				compare_parts(request_parts, path_parts)
			end
		end

		def compare_parts(request_parts, path_parts)
			request_parts.each_with_index do |request_part, i|
				path_part = path_parts[i]
				# p request_part, path_part
				break false unless path_part
				if path_part[0] == ':'
					add_argument(request_part, path_part)
					next
				end
				break false unless request_part == path_part
			end
		end

		def add_argument(request_part, path_part)
			@args[
			  path_part[(path_part[1] == '?' ? 2 : 1)..-1].to_sym
			] = URI.decode(request_part)
		end
	end
end
