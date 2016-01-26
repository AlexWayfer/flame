module Flame
	## Class for Route in Router.routes
	class Route
		attr_reader :attributes

		def initialize(attrs = {})
			@attributes = attrs.merge(
				path_parts: attrs[:path].to_s.split('/').reject(&:empty?)
			)
		end

		def [](key)
			@attributes[key]
		end

		def []=(key, value)
			@attributes[key] = value
		end

		## Create Executable object (route)
		def executable
			Executable.new(self)
		end

		## Compare attributes for `Router.find_route`
		def compare_attributes(attrs)
			attrs.each do |name, value|
				next true if compare_attribute(name, value)
				break false
			end
		end

		## Assign arguments to path for `Controller.path_to`
		def assign_arguments(args = {})
			self[:path_parts]
			  .map { |path_part| assign_argument(path_part, args) }
			  .unshift('').join('/').gsub(%r{\/{2,}}, '/')
		end

		## Extract arguments from request_parts for `execute`
		def arguments(request_parts)
			self[:path_parts].each_with_index.with_object({}) do |(path_part, i), args|
				request_part = request_parts[i]
				path_part_opt = path_part[1] == '?'
				next args unless path_part[0] == ':'
				break args if path_part_opt && request_part.nil?
				args[
				  path_part[(path_part_opt ? 2 : 1)..-1].to_sym
				] = URI.decode(request_part)
			end
		end

		## Helpers for `compare_attributes`
		def compare_attribute(name, value)
			case name
			when :method
				compare_method(value)
			when :path_parts
				compare_path_parts(value)
			else
				self[name] == value
			end
		end

		def compare_method(request_method)
			self[:method].upcase.to_sym == request_method.upcase.to_sym
		end

		def compare_path_parts(request_parts)
			# p route_path
			req_path_parts = self[:path_parts].select { |part| part[1] != '?' }
			return false if request_parts.count < req_path_parts.count
			# compare_parts(request_parts, self[:path_parts])
			request_parts.each_with_index do |request_part, i|
				path_part = self[:path_parts][i]
				# p request_part, path_part
				break false unless path_part
				next if path_part[0] == ':'
				break false unless request_part == path_part
			end
		end

		## Helpers for `assign_arguments`
		def assign_argument(path_part, args = {})
			## Not argument
			return path_part unless path_part[0] == ':'
			## Not required argument
			return args[path_part[2..-1].to_sym] if path_part[1] == '?'
			## Required argument
			param = args[path_part[1..-1].to_sym]
			## Required argument is nil
			fail ArgumentNotAssignedError.new(self[:path], path_part) if param.nil?
			## All is ok
			param
		end

		## Class for Route execution
		class Executable
			def initialize(route)
				@route = route
			end

			## Execute route from Dispatcher
			def run!(dispatcher)
				@ctrl = @route[:controller].new(dispatcher)
				execute_hooks(:before)
				result = @ctrl.send(@route[:action], *arranged_params)
				execute_hooks(:after)
				result
			end

			def execute_errors(status = 500)
				execute_hooks(:error, status)
			end

			private

			## Arguments in order as parameters of method of controller
			def arranged_params
				# action_parameters.each_with_object([]) do |par, arr|
				# 	arr << @ctrl.params[par[1]] if par[0] == :req || @ctrl.params[par[1]]
				# end
				@ctrl.params.values_at(*action_parameters.map { |par| par[1] })
			end

			## Method parameters of route controller#action
			def action_parameters
				@route[:controller].instance_method(@route[:action]).parameters
			end

			## Execute before, after or error hook of Symbol, String or Proc
			def execute_hook(hook)
				case hook
				when Symbol, String
					@ctrl.send(hook.to_sym)
				when Proc
					@ctrl.instance_exec(&hook)
				else
					fail UnexpectedTypeOfHookError.new(hook, @route)
				end
			end

			## Execute before, after or error hooks
			def execute_hooks(*keys)
				hooks = @route[:hooks].dig(*keys)
				# p hooks
				hooks.each { |hook| execute_hook(hook) } if hooks
			end
		end
	end
end
