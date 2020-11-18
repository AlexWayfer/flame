# frozen_string_literal: true

module Flame
	class Router
		## Custom Hash for routes
		class Routes < Hash
			## @param path_parts [Array<String, Flame::Path, Flame::Path::Part>]
			##   path parts for nested keys
			## @example Initialize without keys
			##   Flame::Router::Routes.new # => {}
			## @example Initialize with nested keys
			##   Flame::Router::Routes.new('/foo/bar/baz')
			##   # => { 'foo' => { 'bar' => { 'baz' => {} } } }
			def initialize(*path_parts)
				super()

				path = Flame::Path.new(*path_parts)
				return if path.parts.empty?

				nested_routes = self.class.new Flame::Path.new(*path.parts[1..-1])
				# path.parts.reduce(result) do |hash, part|
				# 	hash[part] ||= self.class.new
				# end
				self[path.parts.first] = nested_routes
			end

			## Move into Hash by equal key
			## @param path_part [String, Flame::Path::Part, Symbol] requested key
			## @return [Flame::Router::Routes, Flame::Router::Route, nil] found value
			## @example Move by static path part
			##   routes = Flame::Router::Routes.new('/foo/bar/baz')
			##   routes['foo'] # => { 'bar' => { 'baz' => {} } }
			## @example Move by HTTP-method
			##   routes = Flame::Router::Routes.new('/foo/bar')
			##   routes['foo']['bar'][:GET] = 42
			##   routes['foo']['bar'][:GET] # => 42
			def [](key)
				if key.is_a? String
					key = Flame::Path::Part.new(key)
				elsif !key.is_a?(Flame::Path::Part) && !key.is_a?(Symbol)
					return
				end
				super
			end

			## Return the first available route (at the first level).
			## @return [Flame::Router::Route] the first route
			def first_route
				values.find { |value| value.is_a?(Route) }
			end

			## Navigate to Routes or Route through static parts or arguments
			## @param path_parts [Array<String, Flame::Path, Flame::Path::Part>]
			##   path or path parts as keys for navigating
			## @return [Flame::Router::Routes, Flame::Router::Route, nil] found value
			## @example Move by static path part and argument
			##   routes = Flame::Router::Routes.new('/foo/:first/bar')
			##   routes.navigate('foo', 'value') # => { 'bar' => {} }
			def navigate(*path_parts)
				path_parts = Flame::Path.new(*path_parts).parts
				return dig_through_opt_args if path_parts.empty?

				endpoint =
					self[path_parts.first] || dig(first_opt_arg_key, path_parts.first)

				endpoint&.navigate(*path_parts[1..-1]) ||
					find_among_arg_keys(path_parts[1..-1])
			end

			## Dig through optional arguments as keys
			## @return [Flame::Router::Routes] return most nested end-point
			##   without optional arguments
			def dig_through_opt_args
				[
					self[first_opt_arg_key]&.dig_through_opt_args,
					self
				]
					.compact.find(&:first_route)
			end

			def allow
				methods = keys.select { |key| key.is_a? Symbol }
				return if methods.empty?

				methods.push(:OPTIONS).join(', ')
			end

			PADDING_SIZE = Router::HTTP_METHODS.map(&:size).max
			PADDING_FORMAT = "%#{PADDING_SIZE}.#{PADDING_SIZE}s"

			## Output routes in human readable format
			def to_s(prefix = '/')
				sort.map do |key, value|
					if key.is_a?(Symbol)
						<<~OUTPUT
							\e[1m#{format PADDING_FORMAT, key} #{prefix}\e[22m
							#{' ' * PADDING_SIZE} \e[3m\e[36m#{value}\e[0m\e[23m
						OUTPUT
					else
						value.to_s(Flame::Path.new(prefix, key))
					end
				end.join
			end

			## Sort routes for human readability
			def sort
				sort_by do |key, _value|
					[
						if key.is_a?(Symbol)
						then Router::HTTP_METHODS.index(key)
						else Float::INFINITY
						end,
						key.to_s
					]
				end
			end

			private

			def find_among_arg_keys(path_parts)
				keys.find do |key|
					next unless key.is_a?(Flame::Path::Part) && key.arg?

					result = self[key].navigate(*path_parts)
					break result if result
				end
			end

			def first_opt_arg_key
				keys.find do |key|
					key.is_a?(Flame::Path::Part) && key.opt_arg?
				end
			end
		end
	end
end
