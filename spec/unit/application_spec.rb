# frozen_string_literal: true

class ApplicationController < Flame::Controller
	def index; end

	def foo
		'Hello from foo!'
	end

	def bar
		'Hello from bar!'
	end

	def baz(first, second, third = nil, fourth = nil); end

	def view
		render :view
	end
end

## Test controller with REST methods for Application
class ApplicationRESTController < Flame::Controller
	def index; end

	def create; end

	def show(id); end

	def update(id); end

	def delete(id); end
end

module ApplicationNamespace
	module Nested
		class IndexController < Flame::Controller
			def index; end
		end
	end

	class Application < Flame::Application
	end
end

def initialize_path_hash(controller:, action:, http_method: :GET, **options)
	route = Flame::Router::Route.new(controller, action)
	ctrl_path = options.fetch :ctrl_path, controller.default_path
	action_path = Flame::Path.new(
		options.fetch(:action_path, action == :index ? '/' : action)
	).adapt(controller, action)
	path_routes, endpoint =
		Flame::Path.new(ctrl_path, action_path).to_routes_with_endpoint
	endpoint[http_method] = route
	path_routes
end

using GorillaPatch::DeepMerge

def initialize_path_hashes(controller, *actions, **actions_with_options)
	actions.map { |action| [action, {}] }.to_h
		.merge(actions_with_options)
		.each_with_object({}) do |(action, options), result|
			result.deep_merge! initialize_path_hash(
				controller: controller, action: action, **options
			)
		end
end

def initialize_rest_route(action)
	Flame::Router::Route.new(ApplicationRESTController, action)
end

def initialize_rest_routes
	{
		GET: initialize_rest_route(:index),
		POST: initialize_rest_route(:create),
		':id' => {
			GET: initialize_rest_route(:show),
			PUT: initialize_rest_route(:update),
			DELETE: initialize_rest_route(:delete)
		}
	}
end

def rest_routes(prefix = nil)
	routes, endpoint = Flame::Path.new(prefix).to_routes_with_endpoint

	endpoint.merge! initialize_rest_routes

	routes
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
			app_class.class_exec { mount :application, '/' }
			view_names = %w[view layout].map do |filename|
				File.join(__dir__, 'views', "#{filename}.html.erb")
			end
			app_class.call(env).first.should.equal 200
			app_class.cached_tilts.size.should.equal 2
			app_class.cached_tilts.keys.should.equal view_names
			app_class.cached_tilts.each_value do |value|
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
				mount :application, '/'
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

	describe '.mount' do
		it 'should add routes from controller without refinings' do
			@app_class.class_exec do
				mount :application
			end

			@app_class.router.routes.should.equal initialize_path_hashes(
				ApplicationController, :index, :foo, :bar, :baz, :view
			)
		end

		it 'should can receive controller with `_controller` in name' do
			@app_class.class_exec do
				mount :application_controller
			end

			@app_class.router.routes.should.equal initialize_path_hashes(
				ApplicationController, :index, :foo, :bar, :baz, :view
			)
		end

		it 'should add routes from controller with another path' do
			@app_class.class_exec do
				mount :application, '/another'
			end

			@app_class.router.routes.should.equal initialize_path_hashes(
				ApplicationController,
				index: { ctrl_path: '/another' },
				foo:   { ctrl_path: '/another' },
				bar:   { ctrl_path: '/another' },
				baz:   { ctrl_path: '/another' },
				view:  { ctrl_path: '/another' }
			)
		end

		it 'should add routes from controller with refining block' do
			@app_class.class_exec do
				mount :application do
				end
			end

			@app_class.router.routes.should.be.any
		end

		it 'should mount controller with overwrited HTTP-methods' do
			@app_class.class_exec do
				mount :application do
					post :baz
				end
			end

			@app_class.router.routes.should.equal initialize_path_hashes(
				ApplicationController,
				:index, :foo, :bar, :view, baz: { http_method: :POST }
			)
		end

		it 'should mount controller with overwrited action path' do
			@app_class.class_exec do
				mount :application do
					get '/bat/:first/:second/:?third/:?fourth', :baz
				end
			end

			@app_class.router.routes.should.equal initialize_path_hashes(
				ApplicationController,
				:index, :foo, :bar, :view, baz: { action_path: '/bat' }
			)
		end

		it 'should mount controller with overwrited arguments order' do
			@app_class.class_exec do
				mount :application do
					get '/baz/:second/:first/:?third/:?fourth', :baz
				end
			end

			@app_class.router.routes.should.equal initialize_path_hashes(
				ApplicationController,
				:index, :foo, :bar, :view,
				baz: { action_path: '/baz/:second/:first/:?third/:?fourth' }
			)
		end

		it 'should mount controller with all of available overwrites' do
			@app_class.class_exec do
				mount :application do
					post '/bat/:second/:first/:?third/:?fourth', :baz
				end
			end

			@app_class.router.routes.should.equal initialize_path_hashes(
				ApplicationController,
				:index, :foo, :bar, :view,
				baz: {
					action_path: '/bat/:second/:first/:?third/:?fourth',
					http_method: :POST
				}
			)
		end

		it 'should mount controller without arguments in path' do
			@app_class.class_exec do
				mount :application do
					post '/bat', :baz
				end
			end

			@app_class.router.routes.should.equal initialize_path_hashes(
				ApplicationController,
				:index, :foo, :bar, :view,
				baz: {
					action_path: '/bat/:first/:second/:?third/:?fourth',
					http_method: :POST
				}
			)
		end

		it 'should mount controller when required arguments are missing' do
			@app_class.class_exec do
				mount :application do
					post '/bat/:second', :baz
				end
			end

			@app_class.router.routes.should.equal initialize_path_hashes(
				ApplicationController,
				:index, :foo, :bar, :view,
				baz: {
					action_path: '/bat/:second/:first/:?third/:?fourth',
					http_method: :POST
				}
			)
		end

		it 'should mount controller when optional arguments are missing' do
			@app_class.class_exec do
				mount :application do
					post '/bat/:second/:first', :baz
				end
			end

			@app_class.router.routes.should.equal initialize_path_hashes(
				ApplicationController,
				:index, :foo, :bar, :view,
				baz: {
					action_path: '/bat/:second/:first/:?third/:?fourth',
					http_method: :POST
				}
			)
		end

		it 'should raise error when method does not exist' do
			block = lambda do
				@app_class.class_exec do
					mount :application do
						post :wat
					end
				end
			end

			block.should.raise(NameError)
				.message.should match_words('wat', 'ApplicationController')
		end

		it 'should raise error when wrong HTTP-method used' do
			block = lambda do
				@app_class.class_exec do
					mount :application do
						wrong :baz
					end
				end
			end

			block.should.raise(NoMethodError)
				.message.should match_words('wrong')
		end

		it 'should raise error with extra required path arguments' do
			block = lambda do
				@app_class.class_exec do
					mount :application do
						get '/baz/:first/:second/:third', :baz
					end
				end
			end
			block.should.raise(Flame::Errors::RouteExtraArgumentsError)
				.message.should match_words('ApplicationController', 'third')
		end

		it 'should raise error with extra optional path arguments' do
			block = lambda do
				@app_class.class_exec do
					mount :application do
						get '/baz/:first/:second/:?third/:?fourth/:?fifth', :baz
					end
				end
			end

			block.should.raise(Flame::Errors::RouteExtraArgumentsError)
				.message.should match_words('ApplicationController', 'fifth')
		end

		it 'should raise error for wrong order of optional arguments' do
			block = lambda do
				@app_class.class_exec do
					mount :application do
						get '/baz/:first/:second/:?fourth/:?third', :baz
					end
				end
			end

			block.should.raise(Flame::Errors::RouteArgumentsOrderError)
				.message.should match_words(
					"'/baz/:first/:second/:?fourth/:?third'", "':?third'", "':?fourth'"
				)
		end

		it 'should mount defaults REST actions' do
			@app_class.class_exec do
				mount :application_REST, '/'
			end

			@app_class.router.routes.should.equal rest_routes
		end

		it 'should overwrite existing routes' do
			@app_class.class_exec do
				mount :application do
					get :baz
					post :baz
				end
			end

			@app_class.router.routes.should.equal initialize_path_hashes(
				ApplicationController,
				:index, :foo, :bar, :view, baz: { http_method: :POST }
			)
		end

		it 'should mount nested controllers' do
			@app_class.class_exec do
				mount :application do
					get :foo

					mount :application_REST, '/rest'
				end
			end

			@app_class.router.routes.should.equal(
				rest_routes('/application/rest').deep_merge!(
					initialize_path_hashes(
						ApplicationController, :index, :foo, :bar, :view, :baz
					)
				)
			)

			@app_class.router.reverse_routes.should.equal(
				'ApplicationController' => {
					index: '/application/',
					foo: '/application/foo',
					bar: '/application/bar',
					view: '/application/view',
					baz: '/application/baz/:first/:second/:?third/:?fourth'
				},
				'ApplicationRESTController' => {
					index: '/application/rest/',
					create: '/application/rest/',
					show: '/application/rest/:id',
					update: '/application/rest/:id',
					delete: '/application/rest/:id'
				}
			)
		end

		it 'should mount neighboring controllers with root-with-argument action' do
			@app_class.class_exec do
				mount :application do
					get '/', :baz

					mount :application_REST, '/rest'
				end
			end

			@app_class.router.routes.should.equal(
				rest_routes('/application/rest').deep_merge!(
					initialize_path_hashes(
						ApplicationController, :index, :foo, :bar, :view,
						baz: { action_path: '/:first/:second/:?third/:?fourth' }
					)
				)
			)

			@app_class.router.reverse_routes.should.equal(
				'ApplicationController' => {
					index: '/application/',
					foo: '/application/foo',
					bar: '/application/bar',
					view: '/application/view',
					baz: '/application/:first/:second/:?third/:?fourth'
				},
				'ApplicationRESTController' => {
					index: '/application/rest/',
					create: '/application/rest/',
					show: '/application/rest/:id',
					update: '/application/rest/:id',
					delete: '/application/rest/:id'
				}
			)
		end

		it 'should mount controller from the same namespace as application' do
			app_class = Class.new(ApplicationNamespace::Application)

			block = lambda do
				app_class.class_exec do
					mount :nested
				end
			end

			block.should.not.raise(NameError)
		end
	end
end
