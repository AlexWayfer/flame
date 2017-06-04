# frozen_string_literal: true

require_relative 'path'
require_relative 'validators'

module Flame
	class Router
		## Class for Route in Router.routes
		class Route
			attr_reader :method, :controller, :action, :path

			def initialize(controller, action, method, ctrl_path, action_path)
				@controller = controller
				@action = action
				@method = method.to_sym.upcase
				## Make path by controller method with parameners
				action_path = Flame::Path.new(action_path).adapt(controller, action)
				## Merge action path with controller path
				@path = Flame::Path.new(ctrl_path, action_path)
				Validators::RouteArgumentsValidator.new(
					@controller, action_path, @action
				).valid?
				freeze
			end

			def freeze
				@path.freeze
				super
			end

			## Compare attributes for `Router.find_route`
			## @param attrs [Hash] Hash of attributes for comparing
			def compare_attributes(attrs)
				attrs.each do |name, value|
					next true if compare_attribute(name, value)
					break false
				end
			end

			## Method for Routes comparison
			def ==(other)
				%i[controller action method path].reduce(true) do |result, method|
					result && (
						public_send(method) == other.public_send(method)
					)
				end
			end

			## Compare by:
			## 1. path parts count (more is matter);
			## 2. args position (father is matter);
			## 3. HTTP-method (default).
			def <=>(other)
				path_result = other.path <=> path
				return path_result unless path_result.zero?
				method <=> other.method
			end

			private

			## Helpers for `compare_attributes`
			def compare_attribute(name, value)
				case name
				when :method
					compare_method(value)
				when :path
					path.match? value
				else
					send(name) == value
				end
			end

			def compare_method(request_method)
				request_method = request_method.upcase.to_sym
				request_method = :GET if request_method == :HEAD
				method.upcase.to_sym == request_method
			end
		end
	end
end
