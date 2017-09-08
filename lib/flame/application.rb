# frozen_string_literal: true

require_relative 'application/config'
require_relative 'router'
require_relative 'dispatcher'

module Flame
	## Core class, like Framework::Application
	class Application
		class << self
			attr_accessor :config

			## Router for routing
			def router
				@router ||= Flame::Router.new(self)
			end

			def cached_tilts
				@cached_tilts ||= {}
			end

			## Require project directories, exclude executable files
			## @param dirs [Array<String>] Array of directories names
			## @example Regular require of project
			##   Flame::Application.require_dirs(
			##     %w[config lib models helpers mailers services controllers]
			##	 )
			def require_dirs(dirs)
				caller_dir = File.dirname caller_file
				dirs.each do |dir|
					Dir[File.join(caller_dir, dir, '**', '*.rb')]
						.reject { |file| File.executable?(file) }
						.sort_by { |s| [File.basename(s)[0], s] }
						.each { |file| require File.expand_path(file) }
				end
			end

			## Generating application config when inherited
			def inherited(app)
				app.config = Config.new(
					app,
					default_config_dirs(
						root_dir: File.dirname(caller_file)
					).merge(
						environment: ENV['RACK_ENV'] || 'development'
					)
				)
			end

			## Make available `run Application` without `.new` for `rackup`
			def call(env)
				@app ||= new
				@app.call env
			end

			private

			## Get filename from caller of method
			## @return [String] filename of caller
			def caller_file
				caller(2..2).first.split(':')[0]
			end

			using GorillaPatch::DeepMerge

			## Mount controller in application class
			## @param controller [Symbol] the snake-cased name of mounted controller
			##   (without `Controller` or `::IndexController` for namespaces)
			## @param path [String, nil] root path for the mounted controller
			## @yield refine defaults pathes for a methods of the mounted controller
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
			def mount(controller_name, path = nil, &block)
				## Add routes from controller to glob array

				routes_refine = Router::RoutesRefine.new(
					router, namespace, controller_name, path, &block
				)

				router.routes.deep_merge! routes_refine.routes
				router.reverse_routes.merge! routes_refine.reverse_routes
			end

			using GorillaPatch::Namespace

			def namespace
				namespace = self
				while namespace.name.nil? && namespace.superclass != Flame::Application
					namespace = superclass
				end
				namespace.deconstantize
			end

			## Initialize default for config directories
			def default_config_dirs(root_dir:)
				result = { root_dir: File.realpath(root_dir) }
				%i[public views config tmp].each do |key|
					result[:"#{key}_dir"] = proc { File.join(config[:root_dir], key.to_s) }
				end
				result
			end
		end

		def initialize(app = nil)
			@app = app
		end

		## Request recieving method
		def call(env)
			@app.call(env) if @app.respond_to? :call
			Flame::Dispatcher.new(self.class, env).run!
		end
	end
end
