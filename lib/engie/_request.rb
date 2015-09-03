require 'rack'

module Engie
	## Helper for request variables
	module Request
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
	end
end
