module Flame
	## Class for requests
	class Request < Rack::Request
		def path_parts
			@path_parts ||= path_info.to_s.split('/').reject(&:empty?)
		end
	end
end
