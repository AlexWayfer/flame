# frozen_string_literal: true

module Flame
	class Dispatcher
		## Helper class for cookies
		class Cookies
			def initialize(request_cookies, response)
				@request_cookies = request_cookies
				@response = response
			end

			## Get request cookies
			## @param key [String, Symbol] name of cookie
			def [](key)
				@request_cookies[key.to_s]
			end

			## Set (or delete) cookies for response
			## @param key [String, Symbol] name of cookie
			## @param new_value [Object, nil] value of cookie
			## @example Set new value to `cat` cookie
			##   cookies['cat'] = 'nice cat'
			## @example Delete `cat` cookie
			##   cookies['cat'] = nil
			def []=(key, new_value)
				return @response.delete_cookie(key.to_s, path: '/') if new_value.nil?
				@response.set_cookie(key.to_s, value: new_value, path: '/')
			end
		end
	end
end
