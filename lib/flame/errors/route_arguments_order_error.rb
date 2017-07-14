# frozen_string_literal: true

module Flame
	module Errors
		## Error for Route initialization
		class RouteArgumentsOrderError < StandardError
			def initialize(path, wrong_ordered_arguments)
				@path = path
				@wrong_ordered_arguments = wrong_ordered_arguments
			end

			def message
				"Path '#{@path}' should have" \
					" '#{@wrong_ordered_arguments.first}' argument before" \
					" '#{@wrong_ordered_arguments.last}'"
			end
		end
	end
end
