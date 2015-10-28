module Flame
	## Class for requests
	class Request < Rack::Request
		def path_parts
			@path_parts ||= path_info.to_s.split('/').reject(&:empty?)
		end

		def http_method
			params['_method'] || request_method
		end
	end
end
