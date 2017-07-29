# frozen_string_literal: true

require 'forwardable'

require_relative 'errors/argument_not_assigned_error'

module Flame
	## Class for working with paths
	class Path
		def self.merge(*parts)
			parts.join('/').gsub(%r{\/{2,}}, '/')
		end

		def initialize(*paths)
			@path = self.class.merge(*paths)
			freeze
		end

		def parts
			@parts ||= @path.to_s.split('/').reject(&:empty?)
				.map! { |part| PathPart.new(part) }
		end

		def freeze
			@path.freeze
			parts.each(&:freeze)
			parts.freeze
			super
		end

		## Compare by parts count and the first arg position
		def <=>(other)
			self_parts, other_parts = [self, other].map(&:parts)
			parts_size = self_parts.size <=> other_parts.size
			return parts_size unless parts_size.zero?
			self_parts.zip(other_parts)
				.reduce(0) do |result, (self_part, other_part)|
					break -1 if self_part.arg? && !other_part.arg?
					break 1 if other_part.arg? && !self_part.arg?
					result
				end
		end

		def ==(other)
			other = self.class.new(other) if other.is_a? String
			parts == other.parts
		end

		## Complete path for the action of controller
		## @todo Add :arg:type support (:id:num, :name:str, etc.)
		def adapt(ctrl, action)
			parameters = ctrl.instance_method(action).parameters
			parameters.map! do |parameter|
				parameter_type, parameter_name = parameter
				path_part = PathPart.new parameter_name, arg: parameter_type
				path_part unless parts.include? path_part
			end
			self.class.new @path.empty? ? "/#{action}" : self, *parameters.compact
		end

		## Can recieve other as String
		def match?(other)
			other = self.class.new(other) if other.is_a? String
			return false unless other_contain_required_parts?(other)
			result = [self, other].map { |path| path.parts.size }.max.times do |i|
				break false unless compare_parts parts[i], other.parts[i]
			end
			result = true if result
			result
		end

		## Extract arguments from other path with values at arguments
		## @param other_path [Flame::Path] other path with values at arguments
		def extract_arguments(other_path)
			parts.each_with_index.with_object({}) do |(part, i), args|
				other_part = other_path.parts[i].to_s
				next args unless part.arg?
				break args if part.opt_arg? && other_part.empty?
				args[
					part[(part.opt_arg? ? 2 : 1)..-1].to_sym
				] = URI.decode(other_part)
			end
		end

		## Assign arguments to path for `Controller.path_to`
		## @param args [Hash] arguments for assigning
		def assign_arguments(args = {})
			result_parts = parts.map { |part| assign_argument(part, args) }.compact
			self.class.merge result_parts.unshift(nil)
		end

		def to_s
			@path
		end
		alias to_str to_s

		private

		def other_contain_required_parts?(other)
			other_parts = other.parts
			req_path_parts = parts.reject(&:opt_arg?)
			fixed_path_parts = parts.reject(&:arg?)
			(fixed_path_parts - other_parts).empty? &&
				other_parts.count >= req_path_parts.count
		end

		def compare_parts(part, other_part)
			return unless part
			return if other_part.nil? && !part.opt_arg?
			# p other_part, part
			return true if part.arg?
			return true if other_part == part
		end

		## Helpers for `assign_arguments`
		def assign_argument(part, args = {})
			## Not argument
			return part unless part.arg?
			## Not required argument
			return args[part[2..-1].to_sym] if part.opt_arg?
			## Required argument
			param = args[part[1..-1].to_sym]
			## Required argument is nil
			error = Errors::ArgumentNotAssignedError.new(@path, part)
			raise error if param.nil?
			## All is ok
			param
		end

		## Class for one part of Path
		class PathPart
			extend Forwardable

			def_delegators :@part, :[], :hash

			ARG_CHAR = ':'
			ARG_CHAR_OPT = '?'

			def initialize(part, arg: false)
				@part = "#{ARG_CHAR if arg}#{ARG_CHAR_OPT if arg == :opt}#{part}"
			end

			def freeze
				@part.freeze
				super
			end

			def ==(other)
				to_s == other.to_s
			end

			alias eql? ==

			def to_s
				@part
			end

			def arg?
				@part.start_with? ARG_CHAR
			end

			def opt_arg?
				@part[1] == ARG_CHAR_OPT
			end

			def clean
				@part.delete ARG_CHAR + ARG_CHAR_OPT
			end
		end
	end
end
