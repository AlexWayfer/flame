require 'rack'
require_relative 'render'

module Flame
	## Class initialize when Dispatcher found route with it
	## For new request and response
	class Controller
		def initialize(dispatcher)
			@dispatcher = dispatcher
		end

		## Helpers
		def path_to(*args)
			args.unshift self.class if args[0].is_a? Symbol
			@dispatcher.path_to(*args)
		end

		def redirect(*params)
			response.redirect(
				params[0].is_a?(String) ? params[0] : path_to(*params)
			)
		end

		def view(path = nil, options = {})
			template = Flame::Render.new(
				self,
				(path || caller_locations(1, 1)[0].label.to_sym),
				options
			)
			template.render(cache: config[:environment] == 'production')
		end
		alias_method :render, :view

		## Helpers from Flame::Dispatcher
		def method_missing(m, *args, &block)
			return super unless @dispatcher.respond_to?(m)
			@dispatcher.send(m, *args, &block)
		end

		private

		using GorillaPatch::StringExt

		def self.default_path(last = false)
			(name.split('::').last.underscore.split('_') - %w(index controller ctrl))
			  .join('/').split('/')
			  .unshift(nil)[(last ? -1 : 0)..-1].join('/')
		end
	end
end
