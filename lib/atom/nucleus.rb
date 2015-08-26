module Atom
	## Core class, like Framework::Application
	class Nucleus
		## Helpers for variables
		def status(value = nil)
			@status ||= 200
			value ? @status = value : @status
		end

		def headers
			@headers ||= { 'Content-Type' => 'text/html' }
		end

		def params
			@request.params
		end

		def request(env = nil)
			env ? @request = Rack::Request.new(env)	: @request
		end

		## Init function
		def call(env)
			request(env)
			block = find_block
			if block
				status 200
				body = instance_exec(*@args, &block)
				[status, headers, [body]]
			else
				[404, {}, ['Not Found']]
			end
		end

		## Functions for routing
		def self.route(path, &block)
			routes[path] = block
		end

		private

		## Helpers for private variables
		def self.routes
			@routes ||= {}
		end

		def routes
			self.class.routes
		end

		## Find block of code for routing
		def find_block
			routes[find_route_key]
		end

		def find_route_key
			routes.keys.detect do |route_path|
				@args = []
				case route_path.class
				when Regexp
					request.path_info =~ route_path
				else
					compare_paths(request.path_info, route_path.to_s)
				end
			end
		end

		def compare_paths(route_path)
			path_parts = route_path.split('/').reject(&:empty?)
			request_parts = request.path_info.split('/').reject(&:empty?)
			return false if request_parts.empty?
			request_parts.each_with_index do |request_part, i|
				compare_parts(request_part, path_parts[i])
			end
		end

		def compare_parts(request_part, path_part)
			break false unless path_part
			if path_part[0] == ':'
				@args << URI.decode(request_part)
				next
			end
			break false unless request_part == path_part
		end
	end
end
