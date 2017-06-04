# frozen_string_literal: true

require_relative 'errors/route_arguments_error'

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
				## Get hash of any extra arguments
				extra = %i[req opt].find do |type|
					found = extra_arguments(type).find do |place, args|
						break { place: place, type: type, args: args } if args.any?
					end
					break found if found
				end
				## Return true if no any extra argument
				return true unless extra
				## Raise error with extra arguments
				raise Errors::RouteArgumentsError.new(@ctrl, @action, @path, extra)
			end

			private

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
	end
end
