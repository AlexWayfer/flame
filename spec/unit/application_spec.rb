# frozen_string_literal: true

class ApplicationController < Flame::Controller
	def index; end

	def foo
		'Hello from foo!'
	end

	def bar
		'Hello from bar!'
	end

	def hello(name)
		"Hello, #{name}!"
	end

	def baz(first, second, third = nil, fourth = nil); end

	def view
		render :view
	end
end

class ApplicationRefinedController < Flame::Controller
	def foo; end

	get def bar; end

	post def baz; end

	put def qux; end

	delete '/refined_quux/:id', def quux(id); end

	def quuz; end
	patch '/refined_quuz', :quuz
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
	subject(:app_class) { Class.new(described_class) }

	subject(:app) { app_class.new(another_app) }

	let(:another_app) { nil }

	let(:env_path) { '/foo' }

	let(:env) do
		{
			Rack::RACK_INPUT => StringIO.new,
			Rack::REQUEST_METHOD => 'GET',
			Rack::PATH_INFO => env_path
		}
	end

	describe '.config' do
		subject { app_class.config }

		it { is_expected.to be_kind_of Flame::Application::Config }
	end

	describe '.config=' do
		before { app_class.config = config }

		subject { app_class.config }

		let(:config) { Flame::Application::Config.new(app_class) }

		it { is_expected.to be config }
	end

	describe '.router' do
		subject { app_class.router }

		it { is_expected.to be_kind_of Flame::Router }
	end

	describe '.cached_tilts' do
		subject { app_class.cached_tilts }

		it { is_expected.to be_kind_of Hash }
		it { is_expected.to be subject }

		describe 'filling' do
			let(:env_path) { '/view' }

			before do
				allow(ENV).to receive(:[]).and_call_original
				allow(ENV).to receive(:[]).with('RACK_ENV').and_return 'production'

				app_class.class_exec do
					mount :application, '/'
				end
			end

			let(:view_names) do
				%w[view layout].map do |filename|
					File.join(__dir__, 'views', "#{filename}.html.erb")
				end
			end

			it 'occurs by controller renders' do
				expect(app_class.call(env).first).to eq 200

				expect(subject.size).to eq 2
				expect(subject.keys).to eq view_names

				subject.each_value do |value|
					expect(value).to be_kind_of Tilt::Template
				end
			end
		end
	end

	describe '.require_dirs' do
		it do
			all_files = Dir[File.join(__dir__, 'require_dirs/**/*')]

			wanted_files = all_files.reject do |file|
				File.executable?(file) || file.match?(%r{lib/\w+/spec/})
			end

			executable_files = all_files.select do |file|
				File.file?(file) && File.executable?(file)
			end

			ignored_files = all_files.select do |file|
				File.file?(file) && file.match?(%r{lib/\w+/spec/})
			end

			allow(Kernel).to receive(:require) do |file|
				expect(wanted_files).to include file
				expect(executable_files).to include file
				expect(ignored_files).to include file
			end

			app_class.require_dirs(
				%w[config lib models helpers mailers services controllers]
					.map! { |dir| File.join 'require_dirs', dir },
				ignore: [%r{lib/\w+/spec}]
			)
		end
	end

	describe '.inherited' do
		describe 'default config' do
			subject { app_class.config }

			it { is_expected.to be_kind_of Flame::Application::Config }

			describe 'values' do
				subject { super()[key] }

				{
					root_dir:    __dir__,
					public_dir:  File.join(__dir__, 'public'),
					views_dir:   File.join(__dir__, 'views'),
					config_dir:  File.join(__dir__, 'config'),
					tmp_dir:     File.join(__dir__, 'tmp'),
					environment: 'development'
				}.each do |key, value|
					describe key.to_s do
						let(:key) { key }
						it { is_expected.to eq value }
					end
				end

				describe 'environment from ENV' do
					before do
						allow(ENV).to receive(:[]).with('RACK_ENV').and_return 'production'
					end

					let(:key) { :environment }

					it { is_expected.to eq 'production' }
				end
			end
		end
	end

	describe '.call' do
		subject { app_class.call(env) }

		it { is_expected.to be_kind_of Array }

		it 'caches created instance' do
			first_app, second_app = Array.new(2) do
				subject
				app.instance_variable_get(:@app)
			end

			expect(first_app).to equal second_app
		end
	end

	describe '.path_to' do
		before do
			app_class.class_exec do
				mount ApplicationController, '/'
			end
		end

		subject { app_class.path_to(*args) }

		context 'controller and action' do
			let(:args) { [ApplicationController, :foo] }

			it { is_expected.to eq '/foo' }
		end

		context 'controller with default index action' do
			let(:args) { [ApplicationController] }

			it { is_expected.to eq '/' }
		end

		context 'controller and action with arguments' do
			let(:args) { [ApplicationController, :hello, name: 'world'] }

			it { is_expected.to eq '/hello/world' }
		end

		context 'nonexistent action' do
			let(:args) { [ApplicationController, :not_exist] }

			it do
				expect { subject }.to raise_error(
					Flame::Errors::RouteNotFoundError,
					/'ApplicationController' [\w\s]+ 'not_exist'/
				)
			end
		end

		context 'nested params' do
			let(:args) do
				[
					ApplicationController, :foo, params: {
						name: 'world',
						nested: { some: 'here', another: %w[there maybe] }
					}
				]
			end

			it do
				is_expected.to eq(
					'/foo?name=world' \
					'&nested[some]=here&nested[another][]=there&nested[another][]=maybe'
				)
			end
		end
	end

	describe '#initialize' do
		describe '@app parameter' do
			let(:another_app) { app_class.new }

			subject { app.instance_variable_get(:@app) }

			it { is_expected.to be another_app }
		end
	end

	describe '#call' do
		subject { app.call(env) }

		context 'with mounted controller' do
			before do
				app_class.class_exec do
					mount :application, '/'
				end
			end

			it { is_expected.to be_kind_of Array }
			it { expect(subject.first).to eq 200 }
			it { expect(subject.last.body).to eq ['Hello from foo!'] }
		end

		context 'initialized with another app' do
			let(:another_app_class) do
				Class.new(described_class) do
					attr_reader :foo

					def call(env)
						@foo = env[:bar]
					end
				end
			end

			let(:another_app) { another_app_class.new }

			let(:env) { super().merge(bar: 'baz') }

			before do
				app.call(env)
			end

			subject { another_app.foo }

			it { is_expected.to eq 'baz' }
		end

		context 'initialized with another app without call method' do
			let(:another_app) { Object.new }

			it { expect { subject }.not_to raise_error }
		end
	end

	describe '.mount' do
		subject { app_class.router.routes }

		context 'controller without refinings' do
			before do
				app_class.class_exec do
					mount :application
				end
			end

			it do
				is_expected.to eq initialize_path_hashes(
					ApplicationController, :index, :foo, :bar, :hello, :baz, :view
				)
			end
		end

		context 'controller with `_controller` in name' do
			before do
				app_class.class_exec do
					mount :application_controller
				end
			end

			it do
				is_expected.to eq initialize_path_hashes(
					ApplicationController, :index, :foo, :bar, :hello, :baz, :view
				)
			end
		end

		context 'controller with another path' do
			before do
				app_class.class_exec do
					mount :application, '/another'
				end
			end

			it do
				is_expected.to eq initialize_path_hashes(
					ApplicationController,
					index: { ctrl_path: '/another' },
					foo:   { ctrl_path: '/another' },
					bar:   { ctrl_path: '/another' },
					hello: { ctrl_path: '/another' },
					baz:   { ctrl_path: '/another' },
					view:  { ctrl_path: '/another' }
				)
			end
		end

		context 'controller with refining block' do
			before do
				app_class.class_exec do
					mount :application do
					end
				end
			end

			it { is_expected.to be_any }
		end

		context 'controller with refining HTTP-methods' do
			before do
				app_class.class_exec do
					mount :application do
						post :baz
					end
				end
			end

			it do
				is_expected.to eq initialize_path_hashes(
					ApplicationController,
					:index, :foo, :bar, :hello, :view, baz: { http_method: :POST }
				)
			end
		end

		context 'controller with overwrited action path' do
			before do
				app_class.class_exec do
					mount :application do
						get '/bat/:first/:second/:?third/:?fourth', :baz
					end
				end
			end

			it do
				is_expected.to eq initialize_path_hashes(
					ApplicationController,
					:index, :foo, :bar, :hello, :view, baz: { action_path: '/bat' }
				)
			end
		end

		context 'controller with overwrited arguments order' do
			before do
				app_class.class_exec do
					mount :application do
						get '/baz/:second/:first/:?third/:?fourth', :baz
					end
				end
			end

			it do
				is_expected.to eq initialize_path_hashes(
					ApplicationController,
					:index, :foo, :bar, :hello, :view,
					baz: { action_path: '/baz/:second/:first/:?third/:?fourth' }
				)
			end
		end

		context 'controller with all of available overwrites' do
			before do
				app_class.class_exec do
					mount :application do
						post '/bat/:second/:first/:?third/:?fourth', :baz
					end
				end
			end

			it do
				is_expected.to eq initialize_path_hashes(
					ApplicationController,
					:index, :foo, :bar, :hello, :view,
					baz: {
						action_path: '/bat/:second/:first/:?third/:?fourth',
						http_method: :POST
					}
				)
			end
		end

		context 'controller without arguments in path' do
			before do
				app_class.class_exec do
					mount :application do
						post '/bat', :baz
					end
				end
			end

			it do
				is_expected.to eq initialize_path_hashes(
					ApplicationController,
					:index, :foo, :bar, :hello, :view,
					baz: {
						action_path: '/bat/:first/:second/:?third/:?fourth',
						http_method: :POST
					}
				)
			end
		end

		context 'controller with missed required arguments' do
			before do
				app_class.class_exec do
					mount :application do
						post '/bat/:second', :baz
					end
				end
			end

			it do
				is_expected.to eq initialize_path_hashes(
					ApplicationController,
					:index, :foo, :bar, :hello, :view,
					baz: {
						action_path: '/bat/:second/:first/:?third/:?fourth',
						http_method: :POST
					}
				)
			end
		end

		context 'controller with missing optional arguments' do
			before do
				app_class.class_exec do
					mount :application do
						post '/bat/:second/:first', :baz
					end
				end
			end

			it do
				is_expected.to eq initialize_path_hashes(
					ApplicationController,
					:index, :foo, :bar, :hello, :view,
					baz: {
						action_path: '/bat/:second/:first/:?third/:?fourth',
						http_method: :POST
					}
				)
			end
		end

		context 'action does not exist' do
			subject do
				app_class.class_exec do
					mount :application do
						post :wat
					end
				end
			end

			it do
				expect { subject }.to raise_error(
					NameError, /`wat' [\w\s]+ `ApplicationController'/
				)
			end
		end

		context 'wrong HTTP-method used' do
			subject do
				app_class.class_exec do
					mount :application do
						wrong :baz
					end
				end
			end

			it do
				expect { subject }.to raise_error(
					NoMethodError, /`wrong'/
				)
			end
		end

		context 'extra required path arguments' do
			subject do
				app_class.class_exec do
					mount :application do
						get '/baz/:first/:second/:third', :baz
					end
				end
			end

			it do
				expect { subject }.to raise_error(
					Flame::Errors::RouteExtraArgumentsError,
					"Action 'ApplicationController#baz' has no " \
					'required arguments [:third]'
				)
			end
		end

		context 'extra optional path arguments' do
			subject do
				app_class.class_exec do
					mount :application do
						get '/baz/:first/:second/:?third/:?fourth/:?fifth', :baz
					end
				end
			end

			it do
				expect { subject }.to raise_error(
					Flame::Errors::RouteExtraArgumentsError,
					"Action 'ApplicationController#baz' has no " \
					'optional arguments [:fifth]'
				)
			end
		end

		context 'wrong order of optional arguments' do
			subject do
				app_class.class_exec do
					mount :application do
						get '/baz/:first/:second/:?fourth/:?third', :baz
					end
				end
			end

			it do
				expect { subject }.to raise_error(
					Flame::Errors::RouteArgumentsOrderError,
					"Path '/baz/:first/:second/:?fourth/:?third' should have " \
					"':?third' argument before ':?fourth'"
				)
			end
		end

		describe 'mounting defaults REST actions' do
			before do
				app_class.class_exec do
					mount :application_REST, '/'
				end
			end

			it { is_expected.to eq rest_routes }
		end

		describe 'overwriting existing routes' do
			before do
				app_class.class_exec do
					mount :application do
						get :baz
						post :baz
					end
				end
			end

			it do
				is_expected.to eq initialize_path_hashes(
					ApplicationController,
					:index, :foo, :bar, :hello, :view, baz: { http_method: :POST }
				)
			end
		end

		context 'nested controllers' do
			before do
				app_class.class_exec do
					mount :application do
						get :foo

						mount :application_REST, '/rest'
					end
				end
			end

			describe 'routes' do
				it do
					is_expected.to eq(
						rest_routes('/application/rest').deep_merge!(
							initialize_path_hashes(
								ApplicationController, :index, :foo, :bar, :hello, :view, :baz
							)
						)
					)
				end
			end

			describe 'reverse routes' do
				subject { app_class.router.reverse_routes }

				it do
					is_expected.to eq(
						'ApplicationController' => {
							index: '/application/',
							foo:   '/application/foo',
							bar:   '/application/bar',
							hello: '/application/hello/:name',
							view:  '/application/view',
							baz:   '/application/baz/:first/:second/:?third/:?fourth'
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
			end
		end

		describe 'mounting neighboring controllers ' \
		         'with root-with-argument action' do
			before do
				app_class.class_exec do
					mount :application do
						get '/', :baz

						mount :application_REST, '/rest'
					end
				end
			end

			describe 'routes' do
				it do
					is_expected.to eq(
						rest_routes('/application/rest').deep_merge!(
							initialize_path_hashes(
								ApplicationController, :index, :foo, :bar, :hello, :view,
								baz: { action_path: '/:first/:second/:?third/:?fourth' }
							)
						)
					)
				end
			end

			describe 'reverse routes' do
				subject { app_class.router.reverse_routes }

				it do
					is_expected.to eq(
						'ApplicationController' => {
							index: '/application/',
							foo:   '/application/foo',
							bar:   '/application/bar',
							hello: '/application/hello/:name',
							view:  '/application/view',
							baz:   '/application/:first/:second/:?third/:?fourth'
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
			end
		end

		context 'controller from the same namespace as application' do
			let(:app_class) { Class.new(ApplicationNamespace::Application) }

			subject do
				app_class.class_exec do
					mount :nested
				end
			end

			it { expect { subject }.not_to raise_error }
		end

		context 'controller with refined HTTP-methods inside' do
			before do
				app_class.class_exec do
					mount :application_refined
				end
			end

			it do
				is_expected.to eq initialize_path_hashes(
					ApplicationRefinedController,
					foo: { http_method: :GET },
					bar: { http_method: :GET },
					baz: { http_method: :POST },
					qux: { http_method: :PUT },
					quux: {
						http_method: :DELETE,
						action_path: '/refined_quux/:id'
					},
					quuz: {
						http_method: :PATCH,
						action_path: '/refined_quuz'
					}
				)
			end
		end
	end
end
