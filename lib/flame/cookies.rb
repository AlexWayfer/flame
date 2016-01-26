module Flame
	## Helper class for cookies
	class Cookies
		def initialize(request_cookies, response)
			@request_cookies = request_cookies
			@response = response
		end

		def [](key)
			@request_cookies[key.to_s]
		end

		def []=(key, new_value)
			return @response.delete_cookie(key.to_s, path: '/') if new_value.nil?
			@response.set_cookie(key.to_s, value: new_value, path: '/')
		end
	end
end
