# frozen_string_literal: true

module Flame
	module Errors
		## Error for not found controller by name in namespace
		class ControllerNotFoundError < StandardError
			## Create a new instance of error
			## @param controller_name [Symbol, String]
			##   name of controller which not found
			## @param namespace [Module]
			##   namespace for which controller not found
			def initialize(controller_name, namespace)
				super(
					"Controller '#{controller_name}' not found for '#{namespace}'"
				)
			end
		end
	end
end
