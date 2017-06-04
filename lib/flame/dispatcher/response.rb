# frozen_string_literal: true

module Flame
	class Dispatcher
		## Class for responses
		class Response < Rack::Response
			## Set Content-Type header directly or by extension
			## @param value [String] value for header or extension of file
			## @return [String] setted value
			## @example Set value directly
			##   content_type = 'text/css'
			## @example Set value by file extension
			##   content_type = '.css'
			def content_type=(value)
				value = Rack::Mime.mime_type(value) if value.start_with? '.'
				set_header Rack::CONTENT_TYPE, value
			end
		end
	end
end
