# frozen_string_literal: true

require 'addressable'

require_relative 'router'
require_relative 'dispatcher'

module Flame
	## Core class, like Framework::Application
	class Application
		class << self
			include Memery

			## Remember root directory when inherited
			def inherited(app)
				super
				app.root_dir = File.dirname caller(2..2).first.split(':')[0]
			end

			memoize def config
				Flame::Config.new root_dir
			end

			## Router for routing
			memoize def router
				Flame::Router.new(self)
			end

			memoize def cached_tilts
				{}
			end

			## Require project directories, exclude executable files
			## @param dirs [Array<String>] Array of directories names
			## @example Regular require of project
			##   Flame::Application.require_dirs(
			##     %w[config lib models helpers mailers services controllers]
			##	 )
			def require_dirs(dirs, ignore: [])
				dirs.each do |dir|
					require_dir File.join(root_dir, dir), ignore: ignore
				end
			end

			## Make available `run Application` without `.new` for `rackup`
			def call(env)
				@app ||= new
				@app.call env
			end

			using GorillaPatch::DeepDup

			## Build a path to the given controller and action
			##
			## @param ctrl [Flame::Controller] class of controller
			## @param action [Symbol] method of controller
			## @param args [Hash] parameters for method of controller
			## @return [String] path for requested method, controller and parameters
			## @example Path for `show(id)` method of `ArticlesController`
			##   path_to ArticlesController, :show, id: 2 # => "/articles/show/2"
			## @example Path for `new` method of `ArticlesController` with query
			##   path_to ArticlesController, :new, author_id: 1
			##   # => "/articles/new?author_id=1"
			def path_to(ctrl, action = :index, args = {})
				path = router.path_of(ctrl, action)

				raise Errors::RouteNotFoundError.new(ctrl, action) unless path

				args = args.deep_dup
				path = path.assign_arguments(args)
				path = '/' if path.empty?
				query = Rack::Utils.build_nested_query args unless args.empty?
				Addressable::URI.new(path: path, query: query).to_s
			end

			protected

			attr_accessor :root_dir

			private

			def require_dir(dir, ignore: [])
				files =
					Dir[File.join(dir, '**/*.rb')]
						.reject do |file|
							File.executable?(file) ||
								ignore.any? { |regexp| regexp.match?(file) }
						end
				files.sort_by! do |file|
					[File.basename(file).start_with?('_') ? 1 : 2, file]
				end
				files.each { |file| require File.expand_path(file) }
			end

			## Mount controller in application class
			## @param controller [Symbol] the snake-cased name of mounted controller
			##   (without `Controller` or `::IndexController` for namespaces)
			## @param path [String, nil] root path for the mounted controller
			## @yield refine defaults paths for a methods of the mounted controller
			## @example Mount controller with defaults
			##   mount :articles # ArticlesController
			## @example Mount controller with specific path
			##   mount :home, '/welcome' # HomeController
			## @example Mount controller with specific path of methods
			##   mount :home do # HomeController
			##     get '/bye', :goodbye
			##     post '/greetings', :new
			##     defaults
			##   end
			## @example Mount controller with nested controllers
			##   mount :cabinet do # Cabinet::IndexController
			##     mount :articles # Cabinet::ArticlesController
			##   end
			def mount(controller, path = nil, nested: true, &)
				## Add routes from controller to glob array
				router.add Router::RoutesRefine.new(
					namespace_name, controller, path, nested: nested, &
				)
			end

			using GorillaPatch::Namespace

			def namespace_name
				namespace = self
				while namespace.name.nil? && namespace.superclass != Flame::Application
					namespace = superclass
				end
				namespace.deconstantize
			end
		end

		def initialize(app = nil)
			@app = app
		end

		## Request receiving method
		def call(env)
			@app.call(env) if @app.respond_to? :call
			Flame::Dispatcher.new(self.class, env).run!
		end
	end
end
