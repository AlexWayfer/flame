# frozen_string_literal: true

require_relative 'errors/route_extra_arguments_error'
require_relative 'errors/route_arguments_order_error'

module Flame
	module Validators
		## Compare arguments from path and from controller's action
		class RouteArgumentsValidator
			def initialize(ctrl, path, action)
				@ctrl = ctrl
				@path = Flame::Path.new(path)
				@action = action
			end

			def valid?
				extra_valid? && order_valid?
			end

			private

			def extra_valid?
				extra_arguments = first_extra_arguments
				## Raise error if extra arguments
				return true unless extra_arguments
				raise Errors::RouteExtraArgumentsError.new(
					@ctrl, @action, @path, extra_arguments
				)
			end

			def order_valid?
				wrong_ordered_arguments = first_wrong_ordered_arguments
				return true unless wrong_ordered_arguments
				raise Errors::RouteArgumentsOrderError.new(
					@path, wrong_ordered_arguments
				)
			end

			## Split path to args array
			def path_arguments
				@path_arguments ||= @path.parts
					.each_with_object(req: [], opt: []) do |part, hash|
						## Take only argument parts
						next unless part.arg?
						## Memorize arguments
						hash[part.opt_arg? ? :opt : :req] << part.clean.to_sym
					end
			end

			## Take args from controller's action
			def action_arguments
				## Get all parameters (arguments) from method
				## Than collect and sort parameters into hash
				@action_arguments ||= @ctrl.instance_method(@action).parameters
					.each_with_object(req: [], opt: []) do |param, hash|
						## Only required parameters must be in `:req`
						hash[param[0]] << param[1]
					end
			end

			## Calculate path and action extra arguments
			def all_extra_arguments
				%i[req opt].each_with_object({}) do |type, extra_arguments|
					extra_arguments[type] = {
						ctrl: action_arguments[type] - path_arguments[type],
						path: path_arguments[type] - action_arguments[type]
					}
				end
			end

			def first_extra_arguments
				## Get hash of any extra arguments
				all_extra_arguments.find do |type, extra_arguments|
					found = extra_arguments.find do |place, args|
						break { place: place, type: type, args: args } if args.any?
					end
					break found if found
				end
			end

			def first_wrong_ordered_arguments
				opt_arguments = action_arguments[:opt].zip(path_arguments[:opt])
				opt_arguments.map! do |args|
					args.map { |arg| Flame::Path::PathPart.new(arg, arg: :opt) }
				end
				opt_arguments.find do |action_argument, path_argument|
					action_argument != path_argument
				end
			end
		end
	end
end
