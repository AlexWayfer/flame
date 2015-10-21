require_relative 'render'

module Flame
	## Class for controllers helpers, like Framework::Controller
	class Controller
		include Flame::Render

		def initialize(dispatcher)
			@dispatcher = dispatcher
		end

		def config
			@dispatcher.config
		end

		def request
			@dispatcher.request
		end

		def params
			@dispatcher.params
		end

		def halt(*params)
			@dispatcher.halt(*params)
		end

		def path_to(*params)
			@dispatcher.path_to(*params)
		end

		## TODO: Add more helpers
	end
end
