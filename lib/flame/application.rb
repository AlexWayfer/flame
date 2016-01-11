require_relative 'router'
require_relative 'request'
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

		## Init function
		def call(env)
			Flame::Dispatcher.new(self, env).run!
		end

		def self.mount(ctrl, path = nil, &block)
			router.add_controller(ctrl, path, block)
		end

		def self.helpers(*modules)
			modules.empty? ? (@helpers ||= []) : @helpers = modules
		end

		## Router for routing
		def self.router
			@router ||= Flame::Router.new(self)
		end

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
