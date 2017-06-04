# frozen_string_literal: true

module Flame
	module Errors
		## Error for Flame::Dispatcher.path_to
		class RouteNotFoundError < StandardError
			def initialize(ctrl, method)
				@ctrl = ctrl
				@method = method
			end

			def message
				"Route with controller '#{@ctrl}' and method '#{@method}'" \
					' not found in application routes'
			end
		end
	end
end
