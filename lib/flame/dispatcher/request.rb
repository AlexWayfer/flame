# frozen_string_literal: true

module Flame
	class Dispatcher
		## Class for requests
		class Request < Rack::Request
			## Initialize Flame::Path
			def path
				@path ||= Flame::Path.new path_info
			end

			## Override HTTP-method of the request if the param '_method' found
			def http_method
				@http_method ||= (params['_method'] || request_method).upcase.to_sym
			end
		end
	end
end
