require_relative 'route'
require_relative 'errors'

module Flame
	module Validators
		## Compare arguments from path and from controller's action
		class ArgumentsValidator
			def initialize(ctrl, path, action)
				@ctrl = ctrl
				@path = path
				@action = action
			end

			def valid?
				## Break path for ':arg' arguments
				@path_args = path_arguments(@path)
				## Take all and required arguments from Controller#action
				@action_args = action_arguments(@action)
				## Compare arguments from path and arguments from method
				no_extra_path_arguments? && no_extra_action_arguments?
			end

			private

			## Split path to args array
			def path_arguments(path)
				args = path.split('/').select { |part| part[0] == Router::ARG_CHAR }
				args.map do |arg|
					opt_arg = arg[1] == Router::ARG_CHAR_OPT
					arg[(opt_arg ? 2 : 1)..-1].to_sym
				end
			end

			## Take args from controller's action
			def action_arguments(action)
				parameters = @ctrl.instance_method(action).parameters
				req_parameters = parameters.select { |par| par[0] == :req }
				{
					all: parameters.map { |par| par[1] },
					req: req_parameters.map { |par| par[1] }
				}
			end

			def no_extra_path_arguments?
				## Subtraction action args from path args
				extra_path_args = @path_args - @action_args[:all]
				return true if extra_path_args.empty?
				raise Errors::RouterError::ExtraPathArgumentsError.new(
					@ctrl, @action, @path, extra_path_args
				)
			end

			def no_extra_action_arguments?
				## Subtraction path args from action required args
				extra_action_args = @action_args[:req] - @path_args
				return true if extra_action_args.empty?
				raise Errors::RouterError::ExtraActionArgumentsError.new(
					@ctrl, @action, @path, extra_action_args
				)
			end
		end

		## Compare actions from routes and from controller
		class ActionsValidator
			def initialize(route_refine)
				@routes_actions = route_refine.routes.map(&:action)
				@ctrl = route_refine.ctrl
				@ctrl_actions = {
					public: @ctrl.public_instance_methods(false),
					all: @ctrl.instance_methods + @ctrl.private_instance_methods
				}
			end

			def valid?
				no_extra_routes_actions? && no_extra_controller_actions?
			end

			private

			def no_extra_routes_actions?
				extra_routes_actions = @routes_actions - @ctrl_actions[:public]
				return true if extra_routes_actions.empty?
				raise Errors::RouterError::ExtraRoutesActionsError.new(
					@ctrl, extra_routes_actions
				)
			end

			def no_extra_controller_actions?
				extra_ctrl_actions = @ctrl_actions[:public] - @routes_actions
				return true if extra_ctrl_actions.empty?
				raise Errors::RouterError::ExtraControllerActionsError.new(
					@ctrl, extra_ctrl_actions
				)
			end
		end
	end
end
