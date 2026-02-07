# frozen_string_literal: true

module Flame
	## Comment due to `private_constant`
	class Router
		## Class for controller constant finding in namespace by names
		class ControllerFinder
			attr_reader :controller

			def initialize(namespace_name, controller_or_name)
				@namespace =
					namespace_name.empty? ? Object : Object.const_get(namespace_name)

				if controller_or_name.is_a?(Class)
					@controller = controller_or_name
					@controller_name = controller_or_name.name
				else
					@controller_name = controller_or_name
					@controller = find
				end
			end

			private

			def find
				found_controller_name = controller_name_variations.find do |variation|
					@namespace.const_defined?(variation) unless variation.empty?
				end

				raise_controller_not_found_error unless found_controller_name

				controller = @namespace.const_get(found_controller_name)
				return controller if controller < Flame::Controller

				controller::IndexController
			end

			using GorillaPatch::Inflections

			TRASNFORMATION_METHODS = %i[camelize upcase].freeze

			private_constant :TRASNFORMATION_METHODS

			def controller_name_variations
				TRASNFORMATION_METHODS.each_with_object([]) do |method, result|
					transformed = @controller_name.to_s.send(method)
					result.push transformed, "#{transformed}Controller"
				end
			end

			def raise_controller_not_found_error
				raise Errors::ControllerNotFoundError.new(@controller_name, @namespace)
			end
		end

		private_constant :ControllerFinder
	end
end
