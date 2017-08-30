# frozen_string_literal: true

module Flame
	class Dispatcher
		## Module for working with routes
		module Routes
			private

			## Find route and try execute it
			def try_route
				route = @app_class.router.find_route(request.path, request.http_method)
				return nil unless route
				status 200
				execute_route(route)
				true
			end

			## Execute route
			## @param route [Flame::Route] route that must be executed
			def execute_route(route, action = route.action)
				params.merge!(
					@app_class.router.path_of(route).extract_arguments(request.path)
				)
				# route.execute(self)
				controller = route.controller.new(self)
				controller.send(:execute, action)
			rescue => exception
				# p 'rescue from dispatcher'
				dump_error(exception)
				status 500
				controller&.send(:server_error, exception)
				# p 're raise exception from dispatcher'
				# raise exception
			end

			## Generate a default body of nearest route
			def default_body_of_nearest_route
				## Return nil if must be no body for current HTTP status
				return if Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.include?(status)
				## Find the nearest route by the parts of requested path
				route = @app_class.router.find_nearest_route(request.path)
				## Return nil if the route not found
				##   or it's `default_body` method not defined
				return default_body unless route
				## Execute `default_body` method for the founded route
				execute_route(route, :default_body)
				default_body if body.empty?
			end
		end
	end
end
