# frozen_string_literal: true

class ApplicationController < Flame::Controller
	def foo
		'Hello from foo!'
	end

	def bar
		'Hello from bar!'
	end

	def view
		render :view
	end
end

describe Flame::Application do
	before do
		ENV.delete 'RACK_ENV'
		@init = proc { Class.new(Flame::Application) }
		@app_class = @init.call
		@app = @app_class.new
		@env_init = proc do |path: '/foo'|
			{
				Rack::RACK_INPUT => StringIO.new,
				Rack::REQUEST_METHOD => 'GET',
				Rack::PATH_INFO => path,
				bar: 'baz'
			}
		end
		@env = @env_init.call
	end

	describe '.config' do
		it 'should return config' do
			@app_class.config.should.be.kind_of Flame::Application::Config
		end
	end

	describe '.config=' do
		it 'should receive config' do
			config = Flame::Application::Config.new(@app_class)
			@app_class.config = config
			@app_class.config.should.be.same_as config
		end
	end

	describe '.router' do
		it 'should return self router' do
			@app_class.router.should.be.kind_of Flame::Router
		end
	end

	describe '.cached_tilts' do
		it 'should be a Hash' do
			@app_class.cached_tilts.should.be.kind_of Hash
		end

		it 'should cache Hash' do
			@app_class.cached_tilts.should.be.same_as @app_class.cached_tilts
		end

		it 'should fill out by controller renders' do
			ENV['RACK_ENV'] = 'production'
			env = @env_init.call(path: '/view')
			app_class = @init.call
			app_class.class_exec { mount ApplicationController, '/' }
			view_names = %w[view layout].map do |filename|
				File.join(__dir__, 'views', "#{filename}.html.erb")
			end
			app_class.call(env).first.should.equal 200
			app_class.cached_tilts.size.should.equal 2
			app_class.cached_tilts.keys.should.equal view_names
			app_class.cached_tilts.values.each do |value|
				value.should.be.kind_of Tilt::Template
			end
		end
	end

	describe '.require_dirs' do
		before do
			@requiring = lambda do
				@app_class.require_dirs(
					%w[config lib models helpers mailers services controllers]
						.map! { |dir| File.join 'require_dirs', dir }
				)
			end
		end

		it 'should not raise any error' do
			@requiring.should.not.raise
		end

		it 'should require all wanted files' do
			@requiring.call
			Dir[File.join(__dir__, 'require_dirs', '**', '*')]
				.reject { |file| File.executable?(file) }
				.each do |file|
					require(file).should.be.false
				end
		end

		it 'should not require executable files' do
			@requiring.call
			Dir[File.join(__dir__, 'require_dirs', '**', '*')]
				.select { |file| File.file?(file) && File.executable?(file) }
				.each do |file|
					require(file).should.be.true
				end
		end
	end

	describe '.inherited' do
		it 'should set default config' do
			@app_class.config.should.be.kind_of Flame::Application::Config
			@app_class.config[:root_dir].should.equal __dir__
			@app_class.config[:public_dir].should.equal File.join(__dir__, 'public')
			@app_class.config[:views_dir].should.equal File.join(__dir__, 'views')
			@app_class.config[:config_dir].should.equal File.join(__dir__, 'config')
			@app_class.config[:tmp_dir].should.equal File.join(__dir__, 'tmp')
			@app_class.config[:environment].should.equal 'development'
		end

		it 'should take environment from ENV' do
			ENV['RACK_ENV'] = 'production'
			@init.call.config[:environment].should.equal 'production'
		end
	end

	describe '.call' do
		it 'should create an instance and call its #call' do
			@app_class.call(@env).should.be.kind_of Array
		end

		it 'should cache created instance' do
			@app_class.call(@env)
			first_app = @app.instance_variable_get(:@app)
			@app_class.call(@env)
			second_app = @app.instance_variable_get(:@app)
			first_app.should.be.same_as second_app
		end
	end

	describe '#config' do
		it 'should return config' do
			@app.config.should.be.kind_of Flame::Application::Config
		end
	end

	describe '#initialize' do
		it 'should take app parameter' do
			another_app = @init.call.new
			@app_class.new(another_app).instance_variable_get(:@app)
				.should.be.same_as another_app
		end
	end

	describe '#call' do
		it 'should return Dispatcher respond' do
			@app_class.class_exec do
				mount ApplicationController, '/'
			end

			response = @app_class.new.call(@env)
			response.should.be.kind_of Array
			response.first.should.equal 200
			response.last.body.should.equal ['Hello from foo!']
		end

		it 'should call app from initialize' do
			another_app_class = @init.call
			another_app_class.class_exec do
				attr_reader :foo

				def call(env)
					@foo = env[:bar]
				end
			end
			another_app = another_app_class.new
			@app_class.new(another_app).call(@env)
			another_app.foo.should.equal 'baz'
		end

		it 'should not call app from initialize without call method' do
			another_app_class = @init.call
			another_app_class.class_exec do
				undef_method :call
			end
			another_app = another_app_class.new
			-> { @app_class.new(another_app).call(@env) }.should.not.raise
		end
	end

	describe '#router' do
		it 'should return class router' do
			@app.router.should.be.kind_of Flame::Router
			@app.router.should.be.same_as @app.class.router
		end
	end
end
