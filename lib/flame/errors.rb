# frozen_string_literal: true
module Flame
	module Errors
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
					"Controller '#{@ctrl}' has no methods" \
					" '#{@extra_actions.join(', ')}' from routes"
				end
			end

			## Error if controller has not assigned in routes actions
			class ExtraControllerActionsError < ActionsError
				def message
					"Routes for '#{@ctrl}' has no methods" \
					" '#{@extra_actions.join(', ')}'"
				end
			end

			## Error for Flame::Router::RouteRefine.arguments_valid?
			class ArgumentsError < StandardError
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
					" does not know arguments '#{@extra_args.join(', ')}'" \
					" from path '#{@path}'"
				end
			end

			## Error if path has no arguments, that controller's method required
			class ExtraActionArgumentsError < ArgumentsError
				def message
					"Path '#{@path}' does not contain required arguments" \
					" '#{@extra_args.join(', ')}' of method '#{@action}'" \
					" from controller '#{@ctrl}'"
				end
			end
		end

		## Error for Flame::Router.find_path
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

		## Error for Flame::Controller.path_to
		class ArgumentNotAssignedError < StandardError
			def initialize(path, path_part)
				@path = path
				@path_part = path_part
			end

			def message
				"Argument '#{@path_part}' for path '#{@path}' is not assigned"
			end
		end

		## Error for Flame::Router.find_path
		class UnexpectedTypeOfHookError < StandardError
			def initialize(hook, route)
				@hook = hook
				@route = route
			end

			def message
				"Unexpected hook-block class '#{@hook.class}'" \
				" in route '#{@route}'"
			end
		end
	end
end
