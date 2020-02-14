# frozen_string_literal: true

require 'memery'

module Flame
	class Controller
		## Module with methods for path or URL building
		module PathTo
			include Memery

			## Look documentation at {Flame::Dispatcher#path_to}
			def path_to(*args)
				add_controller_class(args)
				add_controller_arguments(args)
				@dispatcher.path_to(*args)
			end

			## Build a URI to the given controller and action, or path
			def url_to(*args, **options)
				path = build_path_for_url(*args, **options)
				Addressable::URI.join(request.base_url, path).to_s
			end

			using GorillaPatch::Namespace

			## Path to previous page, or to index action, or to Index controller
			## @return [String] path to previous page or to index
			def path_to_back
				back_path = request.referer
				return back_path if back_path && back_path != request.url

				return path_to :index if self.class.actions.include?(:index)

				'/'
			end

			private

			def add_controller_class(args)
				args.unshift(self.class) if args[0].is_a?(Symbol)
				args.insert(1, :index) if args[0].is_a?(Class) && !args[1].is_a?(Symbol)
			end

			def add_controller_arguments(args)
				if args[-1].is_a?(Hash)
					args[-1] = controller_arguments.merge args[-1]
				else
					args.push(controller_arguments)
				end
			end

			def build_path_for_url(*args, **options)
				first_arg = args.first
				if first_arg.is_a?(String) || first_arg.is_a?(Flame::Path)
					find_static(first_arg).path(with_version: options[:version])
				else
					path_to(*args, **options)
				end
			end

			memoize :build_path_for_url,
				condition: -> { config[:environment] == 'production' }
		end
	end
end
