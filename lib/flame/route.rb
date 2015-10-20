module Flame
	## Class for Route in Router.routes
	class Route
		attr_reader :attributes

		def initialize(attrs = {})
			@attributes = attrs.merge(
				path_parts: extract_path_parts(attrs[:path])
			)
		end

		def [](attribute)
			@attributes[attribute]
		end

		## Arguments in order as parameters of method of controller
		def arrange_arguments(args = {})
			self[:controller].instance_method(self[:action]).parameters
			  .each_with_object([]) do |par, arr|
				  arr << args[par[1]] if par[0] == :req || args[par[1]]
			  end
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

		## Execute by Application.call
		def execute(app)
			ctrl = self[:controller].new(app)
			args = extract_arguments(app.request.path_info)
			app.params.merge!(args)
			ctrl.send(self[:action], *arrange_arguments(args))
		end

		private

		## Helpers for attributes accessors
		def extract_path_parts(other_path = self[:path])
			other_path.to_s.split('/').reject(&:empty?)
		end

		## Extract arguments from request_path for `execute`
		def extract_arguments(request_path)
			args = {}
			request_parts = extract_path_parts(request_path)
			self[:path_parts].each_with_index do |path_part, i|
				next unless path_part[0] == ':'
				args[
				  path_part[(path_part[1] == '?' ? 2 : 1)..-1].to_sym
				] = URI.decode(request_parts[i])
			end
			args
		end

		## Helpers for `compare_attributes`
		def compare_attribute(name, value)
			case name
			when :method
				compare_method(value)
			when :path
				compare_path(value)
			else
				self[name] == value
			end
		end

		def compare_method(request_method)
			self[:method].upcase.to_sym == request_method.upcase.to_sym
		end

		def compare_path(request_path)
			request_parts = extract_path_parts(request_path)
			# p route_path
			req_path_parts = self[:path_parts].select { |part| part[1] != '?' }
			return false if request_parts.count < req_path_parts.count
			compare_parts(request_parts, self[:path_parts])
		end

		def compare_parts(request_parts, path_parts)
			request_parts.each_with_index do |request_part, i|
				path_part = path_parts[i]
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
			fail ArgumentNotAssigned.new(self[:path], path_part) if param.nil?
			## All is ok
			param
		end
	end
end
