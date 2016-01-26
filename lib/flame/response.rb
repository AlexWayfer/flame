module Flame
	## Class for responses
	class Response < Rack::Response
		## Rewrite body assign (reset Content-Length and use #write)
		def body=(value)
			@length = 0
			body.clear
			write value
		end
	end
end
