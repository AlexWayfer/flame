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
				path = Flame::Path.new(*path_parts)
				return if path.parts.empty?
				nested_routes = self.class.new Flame::Path.new(*path.parts[1..-1])
				# path.parts.reduce(result) { |hash, part| hash[part] ||= self.class.new }
				self[path.parts.first] = nested_routes
			end

			## Move into Hash by equal key or through argument-key
			## @param path_part [String, Flame::Path::Part, Symbol] requested key
			## @return [Flame::Router::Routes, Flame::Router::Route, nil] found value
			## @example Move by static path part
			##   routes = Flame::Router::Routes.new('/foo/bar/baz')
			##   routes['foo'] # => { 'bar' => { 'baz' => {} } }
			## @example Move by argument
			##   routes = Flame::Router::Routes.new('/foo/:first/bar')
			##   routes['foo']['value'] # => { 'bar' => {} }
			## @example Move by HTTP-method
			##   routes = Flame::Router::Routes.new('/foo/bar')
			##   routes['foo']['bar'][:GET] = 42
			##   routes['foo']['bar'][:GET] # => 42
			def [](path_part)
				if path_part.is_a? String
					path_part = Flame::Path::Part.new(path_part)
				elsif !path_part.is_a?(Flame::Path::Part) && !path_part.is_a?(Symbol)
					return
				end
				super(path_part) || super(first_req_arg_key)
			end

			## Move like multiple `#[]`
			## @param path_parts [Array<String, Flame::Path, Flame::Path::Part>]
			##   path or path parts as keys for digging
			## @return [Flame::Router::Routes, Flame::Router::Route, nil] found value
			## @example Move by static path part and argument
			##   routes = Flame::Router::Routes.new('/foo/:first/bar')
			##   routes.dig('foo', 'value') # => { 'bar' => {} }
			def dig(*path_parts)
				path_parts = Flame::Path.new(*path_parts).parts
				return self if path_parts.empty?
				endpoint =
					self[path_parts.first] ||
					find { |key, _value| key.is_a?(Flame::Path::Part) && key.arg? }
						&.last
				endpoint&.dig(*path_parts[1..-1])
			end

			## Dig through optional arguments as keys
			## @return [Flame::Router::Routes] return most nested end-point
			##   without optional arguments
			def dig_through_opt_args
				self[first_opt_arg_key]&.dig_through_opt_args || self
			end

			def allow
				methods = keys.select { |key| key.is_a? Symbol }
				return if methods.empty?
				methods.push(:OPTIONS).join(', ')
			end

			## Move like '#dig' with '#dig_through_opt_args'
			## @param path_parts [Array<String, Flame::Path, Flame::Path::Part>]
			def endpoint(*path_parts)
				dig(*path_parts)&.dig_through_opt_args
			end

			private

			%i[req opt].each do |type|
				define_method "first_#{type}_arg_key" do
					keys.find do |key|
						key.is_a?(Flame::Path::Part) && key.public_send("#{type}_arg?")
					end
				end
			end
		end
	end
end
