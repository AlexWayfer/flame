require_relative 'router'
require_relative 'dispatcher'

module Flame
	## Core class, like Framework::Application
	class Application
		class << self
			attr_accessor :config
		end

		## Framework configuration
		def config
			self.class.config
		end

		## Generating application config when inherited
		def self.inherited(app)
			app.config = Config.new(
				app,
				default_config_dirs(
					root_dir: File.dirname(caller[0].split(':')[0])
				).merge(
					environment: ENV['RACK_ENV'] || 'development'
				)
			)
		end

		def initialize(app = nil)
			@app = app
		end

		## Request recieving method
		def call(env)
			@app.call(env) if @app.respond_to? :call
			Flame::Dispatcher.new(self, env).run!
		end

		## Make available `run Application` without `.new` for `rackup`
		def self.call(env)
			@app ||= new
			@app.call env
		end

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
		def self.mount(ctrl, path = nil, &block)
			router.add_controller(ctrl, path, block)
		end

		## Router for routing
		def self.router
			@router ||= Flame::Router.new(self)
		end

		def router
			self.class.router
		end

		## Initialize default for config directories
		def self.default_config_dirs(root_dir:)
			{
				root_dir: File.realpath(root_dir),
				public_dir: proc { File.join(config[:root_dir], 'public') },
				views_dir: proc { File.join(config[:root_dir], 'views') },
				config_dir: proc { File.join(config[:root_dir], 'config') }
			}
		end

		## Class for Flame::Application.config
		class Config < Hash
			def initialize(app, hash = {})
				@app = app
				replace(hash)
			end

			def [](key)
				result = super(key)
				if result.class <= Proc && result.parameters.empty?
					result = @app.class_exec(&result)
				end
				result
			end
		end
	end
end
