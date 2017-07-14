# frozen_string_literal: true

module Flame
	module Errors
		## Error for Route initialization
		class RouteExtraArgumentsError < StandardError
			def initialize(ctrl, action, path, extra)
				@ctrl = ctrl
				@action = action
				@path = path
				@extra = extra
				@extra[:type_name] = {
					req: 'required',
					opt: 'optional'
				}[@extra[:type]]
			end

			def message
				case @extra[:place]
				when :ctrl
					## Error if path has no arguments, that controller's method has
					## NOTE: It isn't using because `Flame::Path#adopt`
					"Path '#{@path}' has no #{@extra[:type_name]}" \
						" arguments #{@extra[:args].inspect}"
				when :path
					## Error if path has more arguments, than controller's method
					"Action '#{@ctrl}##{@action}' has no #{@extra[:type_name]}" \
						" arguments #{@extra[:args].inspect}"
				end
			end
		end
	end
end
