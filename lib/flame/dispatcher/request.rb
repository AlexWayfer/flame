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
				return @http_method if defined?(@http_method)

				method_from_method =
					begin
						params['_method']
					rescue ArgumentError => e
						## https://github.com/rack/rack/issues/337#issuecomment-48555831
						raise unless e.message.include?('invalid %-encoding')
					end

				@http_method = (method_from_method || request_method).upcase.to_sym
			end
		end
	end
end
