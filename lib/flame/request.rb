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
			@env = env
			@status, @headers = nil
			@request = Rack::Request.new(env)
		end

		def halt(new_status, body = '', new_headers = {})
			status new_status
			@headers = new_headers
			if body.empty? && !Rack::Utils::STATUS_WITH_NO_ENTITY_BODY.include?(status)
				body = Rack::Utils::HTTP_STATUS_CODES[status]
			end
			throw :halt, body
		end
	end
end
