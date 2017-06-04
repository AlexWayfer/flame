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

			## Generating application config when inherited
			def inherited(app)
				app.config = Config.new(
					app,
					default_config_dirs(
						root_dir: File.dirname(caller[0].split(':')[0])
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

			## Mount controller in application class
			## @param ctrl [Flame::Controller] the mounted controller class
			## @param path [String, nil] root path for the mounted controller
			## @yield refine defaults pathes for a methods of the mounted controller
			## @example Mount controller with defaults
			##   mount ArticlesController
			## @example Mount controller with specific path
			##   mount HomeController, '/welcome'
			## @example Mount controller with specific path of methods
			##   mount HomeController do
			##     get '/bye', :goodbye
			##     post '/greetings', :new
			##     defaults
			##   end
			def mount(ctrl, path = nil, &block)
				router.add_controller(ctrl, path, &block)
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

		## Framework configuration
		def config
			self.class.config
		end

		def router
			self.class.router
		end

		def initialize(app = nil)
			@app = app
		end

		## Request recieving method
		def call(env)
			@app.call(env) if @app.respond_to? :call
			Flame::Dispatcher.new(self, env).run!
		end
	end
end
