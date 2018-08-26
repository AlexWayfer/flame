# frozen_string_literal: true

require 'gorilla_patch/deep_merge'
require 'gorilla_patch/inflections'
require 'gorilla_patch/namespace'
require 'gorilla_patch/transform'

require_relative 'router/routes'
require_relative 'router/route'

require_relative 'router/controller_finder'
require_relative 'errors/controller_not_found_error'

module Flame
	## Router class for routing
	class Router
		HTTP_METHODS = %i[GET POST PUT PATCH DELETE].freeze

		require_relative 'router/routes_refine'

		extend Forwardable
		def_delegators :routes, :navigate

		attr_reader :app, :routes, :reverse_routes

		## @param app [Flame::Application] host application
		def initialize(app)
			@app = app
			@routes = Flame::Router::Routes.new
			@reverse_routes = {}
		end

		using GorillaPatch::DeepMerge

		## Add RoutesRefine to Router
		## @param routes_refine [Flame::Router::RoutesRefine] refined routes
		def add(routes_refine)
			routes.deep_merge! routes_refine.routes
			reverse_routes.merge! routes_refine.reverse_routes
		end

		## Find the nearest route by path
		## @param path [Flame::Path] path for route finding
		## @return [Flame::Route, nil] return the found nearest route or `nil`
		def find_nearest_route(path)
			path_parts = path.parts.dup
			loop do
				route = routes.navigate(*path_parts)&.values&.grep(Route)&.first
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
	end
end
