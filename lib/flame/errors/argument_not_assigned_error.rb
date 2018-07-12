# frozen_string_literal: true

module Flame
	module Errors
		## Error for Flame::Dispatcher.path_to
		class ArgumentNotAssignedError < StandardError
			## Create a new instance of error
			## @param path [Flame::Path, String] path without argument
			## @param argument [Flame::Path::Part, String, Symbol]
			##   not assigned argument
			def initialize(path, argument)
				super(
					"Argument '#{argument}' for path '#{path}' is not assigned"
				)
			end
		end
	end
end
