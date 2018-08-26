# frozen_string_literal: true

module Flame
	module Errors
		## Error for Route initialization
		class RouteExtraArgumentsError < StandardError
			## Create a new instance of error
			## @param ctrl [Flame::Controller] controller
			## @param action [Symbol] action
			## @param path [Flame::Path, String] path
			## @param extra [Hash] extra arguments
			## @option extra [Symbol] :type required or optional
			## @option extra [Symbol] :place extra arguments in controller or path
			## @option extra [Array<Symbol>] :args extra arguments
			def initialize(ctrl, action, path, extra)
				extra[:type_name] = { req: 'required', opt: 'optional' }[extra[:type]]

				entity = {
					## Error if path has no arguments, that controller's method has
					## NOTE: It isn't using because `Flame::Path#adopt`
					ctrl: "Path '#{path}'",
					## Error if path has more arguments, than controller's method
					path: "Action '#{ctrl}##{action}'"
				}[extra[:place]]

				super(
					"#{entity} has no " \
						"#{extra[:type_name]} arguments #{extra[:args].inspect}"
				)
			end
		end
	end
end
