module Flame
	module RouterError
		## Error for Flame::Router.compare_actions
		class ActionsError < StandardError
			def initialize(ctrl, extra_actions)
				@ctrl = ctrl
				@extra_actions = extra_actions
			end
		end

		## Error if routes have more actions, than controller
		class ExtraRoutesActionsError < ActionsError
			def message
				"Controller '#{@ctrl}' has no methods:" \
				" '#{@extra_actions.join(', ')}'"
			end
		end

		## Error if controller has not assigned in routes actions
		class ExtraControllerActionsError < ActionsError
			def message
				"Routes has no methods from controller '#{@ctrl}':" \
				" '#{@extra_actions.join(', ')}'"
			end
		end

		## Error for Flame::Router::RouteRefine.arguments_valid?
		class ArgumentsError
			def initialize(ctrl, action, path, extra_args)
				@ctrl = ctrl
				@action = action
				@path = path
				@extra_args = extra_args
			end
		end

		## Error if path has more arguments, than controller's method
		class ExtraPathArgumentsError < ArgumentsError
			def message
				"Method '#{@action}' from controller '#{@ctrl}'" \
				" does not know arguments from path '#{@path}':" \
				" '#{@extra_args.join(', ')}'"
			end
		end

		## Error if path has no arguments, that controller's method required
		class ExtraActionArgumentsError < ArgumentsError
			def message
				"Path '#{@path}' does not contain required arguments" \
				" of method '#{@action}' from controller '#{@ctrl}':" \
				" '#{@extra_args.join(', ')}'"
			end
		end
	end
end
