require_relative './errors.rb'

module Flame
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
			args = path.split('/').select { |part| part[0] == ':' }
			args.map { |arg| arg[1..-1].to_sym }
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
			fail RouterError::ExtraPathArgumentsError.new(
				@ctrl, @action, @path, extra_path_args
			)
		end

		def no_extra_action_arguments?
			## Subtraction path args from action required args
			extra_action_args = @action_args[:req] - @path_args
			return true if extra_action_args.empty?
			fail RouterError::ExtraActionArgumentsError.new(
				@ctrl, @action, @path, extra_action_args
			)
		end
	end

	## Compare actions from routes and from controller
	class ActionsValidator
		def initialize(routes, ctrl)
			@routes = routes
			@ctrl = ctrl
		end

		def valid?
			@routes_actions = @routes.map { |route| route[:action] }
			@ctrl_actions = @ctrl.instance_methods(false)
			no_extra_routes_actions? && no_extra_controller_actions?
		end

		private

		def no_extra_routes_actions?
			extra_routes_actions = @routes_actions - @ctrl_actions
			return true if extra_routes_actions.empty?
			fail RouterError::ExtraRoutesActionsError.new(
				@ctrl, extra_routes_actions
			)
		end

		def no_extra_controller_actions?
			extra_ctrl_actions = @ctrl_actions - @routes_actions
			return true if extra_ctrl_actions.empty?
			fail RouterError::ExtraControllerActionsError.new(
				@ctrl, extra_ctrl_actions
			)
		end
	end
end
