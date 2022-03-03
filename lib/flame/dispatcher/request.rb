# frozen_string_literal: true

module Flame
	class Dispatcher
		## Class for requests
		class Request < Rack::Request
			include Memery

			## Initialize Flame::Path
			memoize def path
				Flame::Path.new path_info
			end

			## Override HTTP-method of the request if the param '_method' found
			memoize def http_method
				method_from_method =
					begin
						params['_method']
					rescue ArgumentError => e
						## https://github.com/rack/rack/issues/337#issuecomment-48555831
						raise unless e.message.include?('invalid %-encoding')
					end

				(method_from_method || request_method).upcase.to_sym
			end

			using GorillaPatch::Inflections

			HEADER_PREFIX = 'HTTP_'

			## Helper method for comfortable Camel-Cased Hash of headers
			memoize def headers
				env.each_with_object({}) do |(key, value), result|
					next unless key.start_with?(HEADER_PREFIX)

					camelized_key =
						key.delete_prefix(HEADER_PREFIX).downcase.tr('_', '/').camelize.gsub('::', '-')

					result[camelized_key] = value
				end
			end
		end
	end
end
