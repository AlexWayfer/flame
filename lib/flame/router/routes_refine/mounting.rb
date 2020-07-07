# frozen_string_literal: true

module Flame
	class Router
		class RoutesRefine
			## Module for mounting in RoutesRefine
			module Mounting
				private

				using GorillaPatch::DeepMerge

				## Mount controller inside other (parent) controller
				## @param controller [Flame::Controller] class of mounting controller
				## @param path [String, nil] root path for mounting controller
				## @yield Block of code for routes refine
				def mount(controller_name, path = nil, &block)
					routes_refine = self.class.new(
						@namespace_name, controller_name, path, &block
					)

					@endpoint.deep_merge! routes_refine.routes

					@reverse_routes.merge!(
						routes_refine.reverse_routes.transform_values do |hash|
							hash.transform_values { |action_path| @path + action_path }
						end
					)
				end

				using GorillaPatch::Namespace

				def mount_nested_controllers
					namespace = Object.const_get(@namespace_name)

					namespace.constants.each do |constant_name|
						constant = namespace.const_get(constant_name)
						if constant < Flame::Controller || constant.instance_of?(Module)
							mount_nested_controller constant
						end
					end
				end

				def mount_nested_controller(nested_controller)
					mount nested_controller if should_be_mounted? nested_controller
				end

				def should_be_mounted?(controller)
					if controller.instance_of?(Module)
						controller.const_defined?(:IndexController, false)
					elsif controller.actions.empty? || @reverse_routes.key?(controller.to_s)
						false
					else
						true
					end
				end
			end
		end
	end
end
