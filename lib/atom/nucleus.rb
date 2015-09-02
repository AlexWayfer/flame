require_relative './_request'
require_relative './_render'

module Atom
	## Core class, like Framework::Application
	class Nucleus
		## Framework configuration
		def self.config
			@config ||= {
				request_methods: [:GET, :POST, :PUT, :DELETE]
			}
		end

		def config
			self.class.config
		end

		include Atom::Request
		include Atom::Render

		def self.inherited(app)
			app.config[:root_dir] = File.dirname(caller[0].split(':')[0])
			app.config[:views_dir] = File.join(app.config[:root_dir], 'views')
		end

		## Init function
		def call(env)
			request(env)
			route = find_route
			if route
				status 200
				params.merge!(@args)
				body = instance_exec(*@args.values, &route[:block])
				[status, headers, [body]]
			else
				[404, {}, ['Not Found']]
			end
		end

		## Functions for routing
		def self.method_missing(sym, *args, &block)
			request_method = sym.upcase
			return super unless config[:request_methods].include? request_method
			routes[request_method] << { path: args[0], block: block }
		end

	private

		## Helpers for private variables
		def self.routes
			@routes ||= config[:request_methods].inject({}) do |a, e|
				a.merge(e => [])
			end
		end

		def routes
			self.class.routes
		end

		## Find block of code for routing
		def find_route
			request_method = params['_method'] || request.request_method
			routes[request_method.upcase.to_sym].find do |route|
				@args = {}
				compare_paths(request.path_info, route[:path])
			end
		end

		def compare_paths(request_path, route_path)
			case route_path.class
			when Regexp
				request_path =~ route_path
			else
				path_parts = route_path.to_s.split('/').reject(&:empty?)
				request_parts = request_path.split('/').reject(&:empty?)
				return false if request_parts.count != path_parts.count
				compare_parts(request_parts, path_parts)
			end
		end

		def compare_parts(request_parts, path_parts)
			request_parts.each_with_index do |request_part, i|
				path_part = path_parts[i]
				break false unless path_part
				if path_part[0] == ':'
					@args[path_part[1..-1].to_sym] = URI.decode(request_part)
					next
				end
				break false unless request_part == path_part
			end
		end
	end
end
