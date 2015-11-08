require 'rack'
require_relative 'render'

module Flame
	## Class initialize when Application.call(env) invoked
	## For new request and response
	class Controller
		def initialize(app)
			@app = app
		end

		## Helpers
		def config
			@app.config
		end

		def router
			@app.router
		end

		def request
			@app.request
		end

		def params
			@app.params
		end

		def response
			@app.response
		end

		def status(*args)
			@app.status(*args)
		end

		def halt(*args)
			@app.halt(*args)
		end

		def path_to(*args)
			@app.path_to(*args)
		end

		def redirect(*params)
			throw :halt, response.redirect(
				params[0].is_a?(String) ? params[0] : path_to(*params)
			)
		end

		def session
			request.session
		end

		def cookies
			@cookies ||= Cookies.new(request.cookies, response)
		end

		def view(path, options = {})
			Flame::Render.new(self, path, options).render
		end
		alias_method :render, :view

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
end
