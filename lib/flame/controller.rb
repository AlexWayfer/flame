require_relative 'render'

module Flame
	## Class initialize when Dispatcher found route with it
	## For new request and response
	class Controller
		## Initialize the controller for request execution
		## @param dispatcher [Flame::Dispatcher] dispatcher object
		def initialize(dispatcher)
			@dispatcher = dispatcher
		end

		## Helpers
		def path_to(*args)
			add_controller_class(args)
			@dispatcher.path_to(*args)
		end

		## Redirect for response
		## @overload redirect(path)
		##   Redirect to the string path
		##   @param path [String] path
		##   @example Redirect to '/hello'
		##     redirect '/hello'
		## @overload redirect(*args)
		##   Redirect to the path of `path_to` method
		##   @param args arguments for `path_to` method
		##   @example Redirect to `show` method of `ArticlesController` with id = 2
		##     redirect ArticlesController, :show, id: 2
		def redirect(*params)
			response.redirect(
				params[0].is_a?(String) ? params[0] : path_to(*params)
			)
		end

		## Render a template with `Flame::Render` (based on Tilt-engine)
		## @param path [Symbol, nil] path to the template file
		## @param options [Hash] options for the `Flame::Render` rendering
		## @return [String] rendered template
		def view(path = nil, options = {})
			template = Flame::Render.new(
				self,
				(path || caller_locations(1, 1)[0].label.to_sym),
				options
			)
			template.render(cache: config[:environment] == 'production')
		end
		alias render view

		## Execute the method of the controller with hooks (may be overloaded)
		## @param method [Symbol] name of the controller method
		def execute(method)
			# send method
			body send(
				method,
				*params.values_at(
					*self.class.instance_method(method).parameters.map { |par| par[1] }
				)
			)
		rescue => exception
			# p 'rescue from controller'
			status 500
			dump_error(exception)

			## Re-raise exception for inherited controllers or `Flame::Dispatcher`
			raise exception
		end

		## Call helpers methods from `Flame::Dispatcher`
		def method_missing(m, *args, &block)
			return super unless @dispatcher.respond_to?(m)
			@dispatcher.send(m, *args, &block)
		end

		private

		def add_controller_class(args)
			args.unshift self.class if args[0].is_a? Symbol
		end

		class << self
			using GorillaPatch::StringExt

			## Default root path of the controller for requests
			def default_path
				modules = name.underscore.split('/')
				parts = modules[-1].split('_') - %w(index controller ctrl)
				return modules[-2] if parts.empty?
				parts.join('_')
			end
		end
	end
end
