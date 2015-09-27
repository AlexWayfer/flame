require 'rack'

module Flame
	## Helper for request variables
	module Request
		attr_accessor :request

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

		def new_request(env)
			@request = Rack::Request.new(env)
		end
	end
end
