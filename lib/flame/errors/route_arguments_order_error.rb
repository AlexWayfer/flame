# frozen_string_literal: true

module Flame
	module Errors
		## Error for Route initialization
		class RouteArgumentsOrderError < StandardError
			## Create a new instance of error
			## @param path [Flame::Path, String] path with wrong arguments order
			## @param wrong_ordered_arguments [Array<Symbol>]
			##   two wrong ordered arguments
			def initialize(path, wrong_ordered_arguments)
				super(<<~MESSAGE.chomp)
					Path '#{path}' should have '#{wrong_ordered_arguments.first}' argument before '#{wrong_ordered_arguments.last}'
				MESSAGE
			end
		end
	end
end
