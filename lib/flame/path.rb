# frozen_string_literal: true

require 'forwardable'
require 'memery'

require_relative 'errors/argument_not_assigned_error'

module Flame
	## Class for working with paths
	class Path
		include Memery

		extend Forwardable
		def_delegators :to_s, :include?

		## Merge parts of path to one path
		## @param parts [Array<String, Flame::Path>] parts of expected path
		## @return [Flame::Path] path from parts
		def self.merge(*parts)
			parts.join('/').gsub(%r|/{2,}|, '/')
		end

		## Create a new instance
		## @param paths [String, Flame::Path, Array<String, Flame::Path>]
		##   paths as parts for new path
		def initialize(*paths)
			@path = self.class.merge(*paths)
			freeze
		end

		## Return parts of path, splitted by slash (`/`)
		## @return [Array<Flame::Path::Part>] array of path parts
		memoize def parts
			@path.to_s.split('/').reject(&:empty?)
				.map! { |part| self.class::Part.new(part) }
		end

		## Freeze all strings in object
		def freeze
			@path.freeze
			parts.each(&:freeze)
			parts.freeze
			super
		end

		## Create new instance from self and other by concatinating
		## @param other [Flame::Path, String] other path which will be concatinated
		## @return [Flame::Path] result of concatinating
		def +(other)
			self.class.new(self, other)
		end

		## Compare by parts count and the first arg position
		## @param other [Flame::Path] other path
		## @return [-1, 0, 1] result of comparing
		def <=>(other)
			self_parts, other_parts = [self, other].map(&:parts)
			by_parts_size = self_parts.size <=> other_parts.size
			return by_parts_size unless by_parts_size.zero?

			compare_by_args_in_parts self_parts.zip(other_parts)
		end

		## Compare with other path by parts
		## @param other [Flame::Path, String] other path
		## @return [true, false] equal or not
		def ==(other)
			other = self.class.new(other) if other.is_a? String
			parts == other.parts
		end

		## Complete path for the action of controller
		## @param ctrl [Flame::Controller] to which controller adapt
		## @param action [Symbol] to which action of controller adapt
		## @return [Flame::Path] adapted path
		## @todo Add :arg:type support (:id:num, :name:str, etc.)
		def adapt(ctrl, action)
			parameters = ctrl.instance_method(action).parameters
			parameters.map! do |parameter|
				parameter_type, parameter_name = parameter
				path_part = self.class::Part.new parameter_name, arg: parameter_type
				path_part unless parts.include? path_part
			end
			self.class.new @path.empty? ? "/#{action}" : self, *parameters.compact
		end

		## Extract arguments from other path with values at arguments
		## @param other_path [Flame::Path] other path with values at arguments
		## @return [Hash{Symbol => String}] hash of arguments from two paths
		def extract_arguments(other_path)
			Extractor.new(parts, other_path.parts).run
		end

		## Assign arguments to path for `Controller#path_to`
		## @param args [Hash] arguments for assigning
		def assign_arguments(args = {})
			result_parts = parts.filter_map { |part| assign_argument(part, args) }
			self.class.merge result_parts.unshift(nil)
		end

		## @return [String] path as String
		def to_s
			@path
		end
		alias to_str to_s

		## Path parts as keys of nested Hashes
		## @return [Array(Flame::Router::Routes, Flame::Router::Routes)]
		##   whole Routes (parent) and the endpoint (most nested Routes)
		def to_routes_with_endpoint
			endpoint =
				parts.reduce(result = Flame::Router::Routes.new) do |hash, part|
					hash[part] ||= Flame::Router::Routes.new
				end
			[result, endpoint]
		end

		private

		## Helpers for `assign_arguments`
		def assign_argument(part, args = {})
			## Not argument
			return part unless part.arg?
			## Not required argument
			return args.delete(part[2..].to_sym) if part.opt_arg?

			## Required argument
			param = args.delete(part[1..].to_sym)
			## Required argument is nil
			error = Errors::ArgumentNotAssignedError.new(@path, part)
			raise error if param.nil?

			## All is ok
			param
		end

		def compare_by_args_in_parts(self_and_other_parts)
			result = 0

			self_and_other_parts.each do |self_part, other_part|
				if self_part.arg?
					break result = -1 unless other_part.arg?
				elsif other_part.arg?
					break result = 1
				end
			end

			result
		end

		## Class for extracting arguments from other path
		class Extractor
			def initialize(parts, other_parts)
				@parts = parts
				@other_parts = other_parts

				@index = 0
				@other_index = 0

				@args = {}
			end

			def run
				@parts.each do |part|
					next static_part_found unless part.arg?

					break if part.opt_arg? && @other_parts.count <= @other_index

					@args[part.to_sym] = extract
					@index += 1
				end

				@args
			end

			private

			def static_part_found
				@index += 1
				@other_index += 1
			end

			def extract
				other_part = @other_parts[@other_index]

				return if @parts[@index.next] == other_part

				@other_index += 1
				URI.decode_www_form_component(other_part)
			end
		end

		private_constant :Extractor

		## Class for one part of Path
		class Part
			extend Forwardable

			def_delegators :to_s, :[], :hash, :size, :empty?, :b, :inspect

			ARG_CHAR = ':'
			ARG_CHAR_OPT = '?'

			## Create new instance from String
			## @param part [String] path part as String
			## @param arg [Boolean] is this part an argument
			def initialize(part, arg: false)
				@part = "#{ARG_CHAR if arg}#{ARG_CHAR_OPT if arg == :opt}#{part}"
				freeze
			end

			## Freeze object
			def freeze
				@part.freeze
				super
			end

			## Compare with another
			## @param other [Flame::Path::Part] other path part
			## @return [true, false] equal or not
			def ==(other)
				to_s == other.to_s
			end

			alias eql? ==

			## Convert path part to String
			## @return [String] path part as String
			def to_s
				@part
			end
			alias to_str to_s

			## Is the path part an argument
			## @return [true, false] an argument or not
			def arg?
				@part.start_with? ARG_CHAR
			end

			## Is the path part an optional argument
			## @return [true, false] an optional argument or not
			def opt_arg?
				arg? && @part[1] == ARG_CHAR_OPT
			end

			# def req_arg?
			# 	arg? && !opt_arg?
			# end

			## Path part as a Symbol without arguments characters
			## @return [Symbol] clean Symbol
			def to_sym
				@part.delete(ARG_CHAR + ARG_CHAR_OPT).to_sym
			end
		end
	end
end
