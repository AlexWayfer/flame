require_relative 'route'
require_relative 'validators'

module Flame
	## Router class for routing
	class Router
		attr_accessor :routes, :befores, :afters

		def initialize
			@routes = []
			@befores, @afters = Array.new(2) { {} }
		end

		def add_controller(ctrl, path, block = nil)
			## TODO: Add Regexp paths

			## Add routes from controller to glob array
			ctrl_routes = RouteRefine.new(self, ctrl, path, block)
			ActionsValidator.new(ctrl_routes.routes, ctrl).valid?
			routes.concat(ctrl_routes.routes)
			befores[ctrl] = ctrl_routes.befores
			afters[ctrl] = ctrl_routes.afters
		end

		## Find route by any attributes
		def find_route(attrs, with_hooks = true)
			route = routes.find { |r| r.compare_attributes(attrs) }
			return route unless route && with_hooks
			route.merge(
				befores: find_befores(route),
				afters: find_afters(route)
			)
		end

		## Find before hook by Route
		def find_befores(route)
			(befores[route[:controller]][:*] || []) +
			  (befores[route[:controller]][route[:action]] || [])
		end

		## Find after hook by Route
		def find_afters(route)
			(afters[route[:controller]][:*] || []) +
			  (afters[route[:controller]][route[:action]] || [])
		end

		## Helper module for routing refine
		class RouteRefine
			attr_accessor :rest_routes
			attr_reader :routes, :befores, :afters

			def self.http_methods
				[:GET, :POST, :PUT, :DELETE]
			end

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
				@befores, @afters = Array.new(2) { {} }
				block.nil? ? defaults : instance_exec(&block)
				# p @routes
				@routes.sort! { |a, b| b[:path] <=> a[:path] }
			end

			http_methods.each do |request_method|
				define_method(request_method.downcase) do |path, action = nil|
					if action.nil?
						action = path.to_sym
						path = "/#{path}"
					end
					ArgumentsValidator.new(@ctrl, path, action).valid?
					add_route(request_method, path, action)
				end
			end

			def before(actions, action)
				actions = [actions] unless actions.is_a?(Array)
				actions.each { |a| (@befores[a] ||= []).push(action) }
			end

			def after(actions, action)
				actions = [actions] unless actions.is_a?(Array)
				actions.each { |a| (@afters[a] ||= []).push(action) }
			end

			def defaults
				rest
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

			def mount(ctrl, path = nil, &block)
				path = path_merge(
					@path,
					(path || ctrl.default_path(true))
				)
				@router.add_controller(ctrl, path, block)
			end

			private

			def make_path(path, action = nil, force_params = false)
				## TODO: Add :arg:type support (:id:num, :name:str, etc.)
				unshifted = force_params ? path : action_path(action)
				if path.nil? || force_params
					path = @ctrl.instance_method(action).parameters
					       .map { |par| ":#{par[0] == :req ? '' : '?'}#{par[1]}" }
					       .unshift(unshifted)
					       .join('/')
				end
				path_merge(@path, path)
			end

			def action_path(action)
				action == :index ? '/' : action
			end

			def path_merge(*parts)
				parts.join('/').gsub(%r{\/{2,}}, '/')
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
