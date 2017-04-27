# frozen_string_literal: true

require_relative 'validators'

module Flame
	class Router
		ARG_CHAR = ':'
		ARG_CHAR_OPT = '?'

		## Class for Route in Router.routes
		class Route
			attr_reader :method, :controller, :action, :path, :path_parts

			def initialize(controller, action, method, ctrl_path, action_path)
				## Merge action path with controller path
				path = self.class.path_merge(ctrl_path, action_path)
				@controller = controller
				@action = action
				@method = method.to_sym.upcase
				## MAKE PATH
				@path = path
				Validators::RouteArgumentsValidator.new(
					@controller, action_path, @action
				).valid?
				@path_parts = @path.to_s.split('/').reject(&:empty?)
				freeze
			end

			def freeze
				@path.freeze
				@path_parts.freeze
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

			## Assign arguments to path for `Controller.path_to`
			## @param args [Hash] arguments for assigning
			def assign_arguments(args = {})
				parts = @path_parts.map { |part| assign_argument(part, args) }.compact
				self.class.path_merge(parts.unshift(nil))
			end

			## Extract arguments from request_parts for `execute`
			## @param request_parts [Array] parts of the request (Array of String)
			def arguments(request_parts)
				@path_parts.each_with_index.with_object({}) do |(path_part, i), args|
					request_part = request_parts[i]
					path_part_opt = path_part[1] == ARG_CHAR_OPT
					next args unless path_part[0] == ARG_CHAR
					break args if path_part_opt && request_part.nil?
					args[
						path_part[(path_part_opt ? 2 : 1)..-1].to_sym
					] = URI.decode(request_part)
				end
			end

			## Method for Routes comparison
			def ==(other)
				%i[controller action method path_parts].reduce(true) do |result, method|
					result && (
						public_send(method) == other.public_send(method)
					)
				end
			end

			## Compare by path parts count (more is matter)
			def <=>(other)
				other.path_parts.size <=> path_parts.size
			end

			def self.path_merge(*parts)
				parts.join('/').gsub(%r{\/{2,}}, '/')
			end

			private

			## Helpers for `compare_attributes`
			def compare_attribute(name, value)
				case name
				when :method
					compare_method(value)
				when :path_parts
					compare_path_parts(value)
				else
					send(name) == value
				end
			end

			def compare_method(request_method)
				method.upcase.to_sym == request_method.upcase.to_sym
			end

			def compare_path_parts(request_parts)
				# p route_path
				req_path_parts = @path_parts.reject { |part| part[1] == ARG_CHAR_OPT }
				return false if request_parts.count < req_path_parts.count
				# compare_parts(request_parts, self[:path_parts])
				request_parts.each_with_index do |request_part, i|
					path_part = @path_parts[i]
					# p request_part, path_part
					break false unless path_part
					next if path_part[0] == ARG_CHAR
					break false unless request_part == path_part
				end
			end

			## Helpers for `assign_arguments`
			def assign_argument(path_part, args = {})
				## Not argument
				return path_part unless path_part[0] == ARG_CHAR
				## Not required argument
				return args[path_part[2..-1].to_sym] if path_part[1] == ARG_CHAR_OPT
				## Required argument
				param = args[path_part[1..-1].to_sym]
				## Required argument is nil
				error = Errors::ArgumentNotAssignedError.new(path, path_part)
				raise error if param.nil?
				## All is ok
				param
			end
		end
	end
end
