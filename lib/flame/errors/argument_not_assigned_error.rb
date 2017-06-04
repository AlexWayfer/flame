# frozen_string_literal: true

module Flame
	module Errors
		## Error for Flame::Dispatcher.path_to
		class ArgumentNotAssignedError < StandardError
			def initialize(path, argument)
				@path = path
				@argument = argument
			end

			def message
				"Argument '#{@argument}' for path '#{@path}' is not assigned"
			end
		end
	end
end
