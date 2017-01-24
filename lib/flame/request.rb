module Flame
	## Class for requests
	class Request < Rack::Request
		## Split path of the request to parts (Array of String)
		def path_parts
			@path_parts ||= path_info.to_s.split('/').reject(&:empty?)
		end

		## Override HTTP-method of the request if the param '_method' found
		def http_method
			params['_method'] || request_method
		end

		## Return fullpath without trailing slashes
		def fullpath_without_trailing_slashes
			fullpath.gsub(%r{(?<=.)\/+(?=$|\?)}, '')
		end
	end
end
