require_relative 'render'

module Flame
	## Class for controllers helpers, like Framework::Controller
	class Controller
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

		def view(path, options = {})
			Flame::Render.new(self, path, options).render
		end
		alias_method :render, :view

		def halt(*params)
			@dispatcher.halt(*params)
		end

		def path_to(*params)
			@dispatcher.path_to(*params)
		end

		## TODO: Add more helpers
	end
end
