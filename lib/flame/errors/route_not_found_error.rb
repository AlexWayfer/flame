# frozen_string_literal: true

module Flame
	module Errors
		## Error for Flame::Dispatcher.path_to
		class RouteNotFoundError < StandardError
			## Create a new instance of error
			## @param controller [Flame::Controller]
			##   controller with which route not found
			## @param action [Symbol] action with which route not found
			def initialize(controller, action)
				super(
					"Route with controller '#{controller}' and action '#{action}'" \
					' not found in application routes'
				)
			end
		end
	end
end
