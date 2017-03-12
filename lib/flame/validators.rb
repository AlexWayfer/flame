# frozen_string_literal: true
require_relative 'route'
require_relative 'errors'

module Flame
	module Validators
		## Compare arguments from path and from controller's action
		class RouteArgumentsValidator
			def initialize(ctrl, path, action)
				@ctrl = ctrl
				@path = path
				@action = action
			end

			def valid?
				## Get hash of any extra arguments
				extra = %i(req opt).find do |type|
					found = extra_arguments(type).find do |place, args|
						break { place: place, type: type, args: args } if args.any?
					end
					break found if found
				end
				## Return true if no any extra argument
				return true unless extra
				## Raise error with extra arguments
				raise Errors::RouterError::RouteArgumentsError.new(
					@ctrl, @action, @path, extra
				)
			end

			private

			## Split path to args array
			def path_arguments
				@path_arguments ||= @path.split('/')
					.each_with_object(req: [], opt: []) do |part, hash|
						## Take only argument parts
						next if part[0] != Router::ARG_CHAR
						## Clean argument from special chars
						clean_part = part.delete(
							Router::ARG_CHAR + Router::ARG_CHAR_OPT
						).to_sym
						## Memorize arguments
						hash[part[1] != Router::ARG_CHAR_OPT ? :req : :opt] << clean_part
					end
			end

			## Take args from controller's action
			def action_arguments
				return @action_arguments if @action_arguments
				## Get all parameters (arguments) from method
				## Than collect and sort parameters into hash
				@ctrl.instance_method(@action).parameters
					.each_with_object(req: [], opt: []) do |param, hash|
						## Only required parameters must be in `:req`
						hash[param[0]] << param[1]
					end
			end

			## Calculate path and action extra arguments
			def extra_arguments(type)
				{
					ctrl: action_arguments[type] - path_arguments[type],
					path: path_arguments[type] - action_arguments[type]
				}
			end
		end

		## Compare actions from routes and from controller
		class ActionsValidator
			def initialize(route_refine)
				@routes_actions = route_refine.routes.map(&:action)
				@ctrl = route_refine.ctrl
			end

			def valid?
				no_extra_routes_actions? && no_extra_controller_actions?
			end

			private

			def no_extra_routes_actions?
				extra_routes_actions = @routes_actions - @ctrl.actions
				return true if extra_routes_actions.empty?
				raise Errors::RouterError::ExtraRoutesActionsError.new(
					@ctrl, extra_routes_actions
				)
			end

			def no_extra_controller_actions?
				extra_ctrl_actions = @ctrl.actions - @routes_actions
				return true if extra_ctrl_actions.empty?
				raise Errors::RouterError::ExtraControllerActionsError.new(
					@ctrl, extra_ctrl_actions
				)
			end
		end
	end
end
