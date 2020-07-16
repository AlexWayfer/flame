# frozen_string_literal: true

class ApplicationController < Flame::Controller
	def index; end

	def foo
		'Hello from foo!'
	end

	def bar; end

	def hello(name); end

	def baz(first, second, third = nil, fourth = nil); end

	def view
		render :view
	end
end

module TestRefinedActions
	extend Flame::Controller::Actions

	post def injected; end

	put 'module/update',
		def update; end
end

class ApplicationRefinedActionsController < Flame::Controller
	include with_actions TestRefinedActions, exclude: %i[injected]

	def foo; end

	get def bar; end

	post def baz; end

	put def qux; end

	delete '/refined_quux/:id',
		def quux(id); end

	def quuz; end
	patch '/refined_quuz', :quuz
end

class ApplicationRefinedPathController < Flame::Controller
	PATH = '/that_path_is_refined'

	def index; end

	def show(id); end
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

module ApplicationControllers
	class Controller < Flame::Controller
	end

	module Site
		class Controller < ApplicationControllers::Controller
		end

		class IndexController < Site::Controller
			def index; end

			def about; end
		end

		class PagesController < Site::Controller
			def show(id); end
		end

		module Cabinet
			class Controller < Site::Controller
			end

			class IndexController < Cabinet::Controller
				def index; end
			end

			class SignInController < Cabinet::Controller
				def index; end

				def sign_in_post; end
				post '/', :sign_in_post
			end

			module Common
				class Controller < Cabinet::Controller
				end
			end

			module Admin
				class IndexController < Cabinet::Controller
					def index; end
				end

				class UsersController < Cabinet::Common::Controller
					def index; end

					def show(id); end

					def update(id); end

					def delete(id); end
				end
			end
		end
	end

	module API
		class Controller < ApplicationControllers::Controller
		end

		class IndexController < API::Controller
			def index; end

			def about; end
		end

		class FooController < API::Controller
			def show(id); end
		end

		module Restricted
			class Controller < API::Controller
			end

			class IndexController < Restricted::Controller
				def index; end
			end

			class UsersController < Restricted::Controller
				def index; end

				def show(id); end

				def update(id); end

				def delete(id); end
			end
		end
	end

	class Application < Flame::Application
	end
end

def initialize_path_hash(
	controller:, prefix:, action:, http_method: :GET, **options
)
	route = Flame::Router::Route.new(controller, action)
	ctrl_path = options.fetch :ctrl_path, controller.path
	action_path = Flame::Path.new(
		options.fetch(:action_path, action == :index ? '/' : action)
	).adapt(controller, action)
	path_routes, endpoint =
		Flame::Path.new(prefix, ctrl_path, action_path).to_routes_with_endpoint
	endpoint[http_method] = route
	path_routes
end

using GorillaPatch::DeepMerge

def initialize_path_hashes(
	controller, *actions, prefix: nil, **actions_with_options
)
	actions.map { |action| [action, {}] }.to_h
		.merge(actions_with_options)
		.each_with_object({}) do |(action, options), result|
			result.deep_merge! initialize_path_hash(
				controller: controller, prefix: prefix, action: action, **options
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
	subject(:app) { app_class.new(another_app) }

	let(:app_class) { Class.new(described_class) }

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

		it { is_expected.to be_kind_of Flame::Config }
	end

	describe '.router' do
		subject { app_class.router }

		it { is_expected.to be_kind_of Flame::Router }
	end

	describe '.cached_tilts' do
		subject(:cached_tilts) { app_class.cached_tilts }

		it { is_expected.to be_kind_of Hash }

		describe 'filling' do
			let(:call_result) { app_class.call(env) }

			let(:env_path) { '/view' }

			let(:view_names) do
				%w[view layout].map do |filename|
					File.join(__dir__, 'views', "#{filename}.html.erb")
				end
			end

			before do
				allow(ENV).to receive(:[]).and_call_original
				allow(ENV).to receive(:[]).with('RACK_ENV').and_return 'production'

				app_class.class_exec do
					mount :application, '/'
				end

				call_result
			end

			describe 'status' do
				subject { call_result.first }

				it { is_expected.to eq 200 }
			end

			describe 'size' do
				subject { cached_tilts.size }

				it { is_expected.to eq 2 }
			end

			describe 'keys' do
				subject { cached_tilts.keys }

				it { is_expected.to eq view_names }
			end

			describe 'values' do
				subject { cached_tilts.values }

				it { is_expected.to all a_kind_of(Tilt::Template) }
			end
		end
	end

	describe '.require_dirs' do
		let(:expected_files) do
			%w[
				config/config

				lib/some_lib/lib/some_lib

				models/_some_model_module
				models/some_model

				helpers/some_helper

				mailers/_base
				mailers/some_mailer

				services/_base
				services/_common/_base
				services/regular/_base
				services/_common/create
				services/_common/find
				services/another/find
				services/another_service
				services/regular/all
				services/regular/create
				services/something_service

				controllers/_base_controller
				controllers/site/_controller
				controllers/site/index_controller
			]
		end

		let(:required_files) { [] }

		before do
			allow(app_class).to receive(:require) do |file|
				required_files.push(
					file.sub("#{__dir__}/require_dirs/", '').delete_suffix('.rb')
				)
			end

			app_class.require_dirs(
				%w[config lib models helpers mailers services controllers]
					.map! { |dir| File.join 'require_dirs', dir },
				ignore: [%r{lib/\w+/spec}]
			)
		end

		it do
			# puts required_files
			expect(required_files).to eq expected_files
		end
	end

	describe '.inherited' do
		describe 'default config' do
			subject { app_class.config }

			it { is_expected.to be_kind_of Flame::Config }

			describe 'values' do
				subject { super()[key] }

				{
					root_dir: __dir__,
					public_dir: File.join(__dir__, 'public'),
					views_dir: File.join(__dir__, 'views'),
					config_dir: File.join(__dir__, 'config'),
					tmp_dir: File.join(__dir__, 'tmp'),
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
		subject(:result) { app_class.call(env) }

		it { is_expected.to be_kind_of Array }

		it 'caches created instance' do
			first_app, second_app = Array.new(2) do
				result
				app.instance_variable_get(:@app)
			end

			expect(first_app).to equal second_app
		end
	end

	describe '.path_to' do
		subject(:result) { app_class.path_to(*args) }

		before do
			app_class.class_exec do
				mount :application, '/'
			end
		end

		context 'with controller and action' do
			let(:args) { [ApplicationController, :foo] }

			it { is_expected.to eq '/foo' }
		end

		context 'with controller and default index action' do
			let(:args) { [ApplicationController] }

			it { is_expected.to eq '/' }
		end

		context 'with controller and action with arguments' do
			let(:args) { [ApplicationController, :hello, { name: 'world' }] }

			it { is_expected.to eq '/hello/world' }
		end

		context 'with nonexistent action' do
			let(:args) { [ApplicationController, :not_exist] }

			it do
				expect { result }.to raise_error(
					Flame::Errors::RouteNotFoundError,
					/'ApplicationController' [\w\s]+ 'not_exist'/
				)
			end
		end

		context 'with nested params' do
			let(:args) do
				[
					ApplicationController, :foo, {
						name: 'world',
						nested: { some: 'here', another: %w[there maybe] }
					}
				]
			end

			let(:expected_result) do
				<<~PATH.delete("\n")
					/foo?
					name=world&
					nested[some]=here&
					nested[another][]=there&
					nested[another][]=maybe
				PATH
			end

			it { is_expected.to eq expected_result }
		end
	end

	describe '#initialize' do
		describe '@app parameter' do
			subject { app.instance_variable_get(:@app) }

			let(:another_app) { app_class.new }

			it { is_expected.to be another_app }
		end
	end

	describe '#call' do
		subject(:call_result) { app.call(env) }

		context 'with mounted controller' do
			before do
				app_class.class_exec do
					mount :application, '/'
				end
			end

			it { is_expected.to be_kind_of Array }

			describe 'status' do
				subject { super().first }

				it { is_expected.to eq 200 }
			end

			describe 'body' do
				subject { super().last }

				it { is_expected.to eq ['Hello from foo!'] }
			end
		end

		context 'when initialized with another app' do
			subject(:foo) { another_app.foo }

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

			before { call_result }

			it { is_expected.to eq 'baz' }

			context 'without call method' do
				let(:another_app_class) { Object }

				it { expect { call_result }.not_to raise_error }
			end
		end
	end

	describe '.mount' do
		subject(:routes) { app_class.router.routes }

		context 'when controller without refinings' do
			before do
				app_class.class_exec do
					mount :application
				end
			end

			it do
				expect(routes).to eq initialize_path_hashes(
					ApplicationController, :index, :foo, :bar, :hello, :baz, :view
				)
			end
		end

		context 'when controller with `_controller` in name' do
			before do
				app_class.class_exec do
					mount :application_controller
				end
			end

			it do
				expect(routes).to eq initialize_path_hashes(
					ApplicationController, :index, :foo, :bar, :hello, :baz, :view
				)
			end
		end

		context 'when controller with another path' do
			before do
				app_class.class_exec do
					mount :application, '/another'
				end
			end

			let(:expected_paths) do
				{
					index: { ctrl_path: '/another' },
					foo: { ctrl_path: '/another' },
					bar: { ctrl_path: '/another' },
					hello: { ctrl_path: '/another' },
					baz: { ctrl_path: '/another' },
					view: { ctrl_path: '/another' }
				}
			end

			it do
				expect(routes).to eq initialize_path_hashes(
					ApplicationController, **expected_paths
				)
			end
		end

		context 'when controller with refining block' do
			before do
				app_class.class_exec do
					mount :application do
					end
				end
			end

			it { is_expected.to be_any }
		end

		context 'when controller with refining HTTP-methods' do
			before do
				app_class.class_exec do
					mount :application do
						post :baz
					end
				end
			end

			it do
				expect(routes).to eq initialize_path_hashes(
					ApplicationController,
					:index, :foo, :bar, :hello, :view, baz: { http_method: :POST }
				)
			end
		end

		context 'when controller with overwrited action path' do
			before do
				app_class.class_exec do
					mount :application do
						get '/bat/:first/:second/:?third/:?fourth', :baz
					end
				end
			end

			it do
				expect(routes).to eq initialize_path_hashes(
					ApplicationController,
					:index, :foo, :bar, :hello, :view, baz: { action_path: '/bat' }
				)
			end
		end

		context 'when controller with overwrited arguments order' do
			before do
				app_class.class_exec do
					mount :application do
						get '/baz/:second/:first/:?third/:?fourth', :baz
					end
				end
			end

			it do
				expect(routes).to eq initialize_path_hashes(
					ApplicationController,
					:index, :foo, :bar, :hello, :view,
					baz: { action_path: '/baz/:second/:first/:?third/:?fourth' }
				)
			end
		end

		context 'when controller with all of available overwrites' do
			before do
				app_class.class_exec do
					mount :application do
						post '/bat/:second/:first/:?third/:?fourth', :baz
					end
				end
			end

			let(:expected_simple_paths) do
				%i[index foo bar hello view]
			end

			let(:expected_paths_with_options) do
				{
					baz: {
						action_path: '/bat/:second/:first/:?third/:?fourth',
						http_method: :POST
					}
				}
			end

			it do
				expect(routes).to eq initialize_path_hashes(
					ApplicationController,
					*expected_simple_paths,
					**expected_paths_with_options
				)
			end
		end

		context 'when controller without arguments in path' do
			before do
				app_class.class_exec do
					mount :application do
						post '/bat', :baz
					end
				end
			end

			let(:expected_simple_paths) do
				%i[index foo bar hello view]
			end

			let(:expected_paths_with_options) do
				{
					baz: {
						action_path: '/bat/:first/:second/:?third/:?fourth',
						http_method: :POST
					}
				}
			end

			it do
				expect(routes).to eq initialize_path_hashes(
					ApplicationController,
					*expected_simple_paths,
					**expected_paths_with_options
				)
			end
		end

		context 'when controller with missed required arguments' do
			before do
				app_class.class_exec do
					mount :application do
						post '/bat/:second', :baz
					end
				end
			end

			let(:expected_simple_paths) do
				%i[index foo bar hello view]
			end

			let(:expected_paths_with_options) do
				{
					baz: {
						action_path: '/bat/:second/:first/:?third/:?fourth',
						http_method: :POST
					}
				}
			end

			it do
				expect(routes).to eq initialize_path_hashes(
					ApplicationController,
					*expected_simple_paths,
					**expected_paths_with_options
				)
			end
		end

		context 'when controller with missing optional arguments' do
			before do
				app_class.class_exec do
					mount :application do
						post '/bat/:second/:first', :baz
					end
				end
			end

			let(:expected_simple_paths) do
				%i[index foo bar hello view]
			end

			let(:expected_paths_with_options) do
				{
					baz: {
						action_path: '/bat/:second/:first/:?third/:?fourth',
						http_method: :POST
					}
				}
			end

			it do
				expect(routes).to eq initialize_path_hashes(
					ApplicationController,
					*expected_simple_paths,
					**expected_paths_with_options
				)
			end
		end

		context 'when action does not exist' do
			subject(:mounting) do
				app_class.class_exec do
					mount :application do
						post :wat
					end
				end
			end

			it do
				expect { mounting }.to raise_error(
					NameError, /`wat' [\w\s]+ `ApplicationController'/
				)
			end
		end

		context 'with wrong HTTP-method' do
			subject(:mounting) do
				app_class.class_exec do
					mount :application do
						wrong :baz
					end
				end
			end

			it do
				expect { mounting }.to raise_error(
					NoMethodError, /`wrong'/
				)
			end
		end

		context 'with extra required path arguments' do
			subject(:mounting) do
				app_class.class_exec do
					mount :application do
						get '/baz/:first/:second/:third', :baz
					end
				end
			end

			it do
				expect { mounting }.to raise_error(
					Flame::Errors::RouteExtraArgumentsError,
					"Action 'ApplicationController#baz' has no " \
					'required arguments [:third]'
				)
			end
		end

		context 'with extra optional path arguments' do
			subject(:mounting) do
				app_class.class_exec do
					mount :application do
						get '/baz/:first/:second/:?third/:?fourth/:?fifth', :baz
					end
				end
			end

			it do
				expect { mounting }.to raise_error(
					Flame::Errors::RouteExtraArgumentsError,
					"Action 'ApplicationController#baz' has no " \
					'optional arguments [:fifth]'
				)
			end
		end

		context 'with wrong order of optional arguments' do
			subject(:mounting) do
				app_class.class_exec do
					mount :application do
						get '/baz/:first/:second/:?fourth/:?third', :baz
					end
				end
			end

			it do
				expect { mounting }.to raise_error(
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

			let(:expected_simple_paths) do
				%i[index foo bar hello view]
			end

			let(:expected_paths_with_options) do
				{
					baz: { http_method: :POST }
				}
			end

			it do
				expect(routes).to eq initialize_path_hashes(
					ApplicationController,
					*expected_simple_paths,
					**expected_paths_with_options
				)
			end
		end

		context 'with nested controllers' do
			before do
				app_class.class_exec do
					mount :application do
						get :foo

						mount :application_REST, '/rest'
					end
				end
			end

			let(:expected_routes) do
				rest_routes('/application/rest').deep_merge!(
					initialize_path_hashes(
						ApplicationController, :index, :foo, :bar, :hello, :view, :baz
					)
				)
			end

			it { expect(routes).to eq expected_routes }

			describe 'reverse routes' do
				subject(:reverse_routes) { app_class.router.reverse_routes }

				let(:expected_routes) do
					{
						'ApplicationController' => {
							index: '/application/',
							foo: '/application/foo',
							bar: '/application/bar',
							hello: '/application/hello/:name',
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
					}
				end

				it { expect(reverse_routes).to eq expected_routes }
			end
		end

		describe(
			'mounting neighboring controllers with root-with-argument action'
		) do
			before do
				app_class.class_exec do
					mount :application do
						get '/', :baz

						mount :application_REST, '/rest'
					end
				end
			end

			describe 'routes' do
				let(:expected_routes) do
					rest_routes('/application/rest').deep_merge!(
						initialize_path_hashes(
							ApplicationController, :index, :foo, :bar, :hello, :view,
							baz: { action_path: '/:first/:second/:?third/:?fourth' }
						)
					)
				end

				it { is_expected.to eq expected_routes }
			end

			describe 'reverse routes' do
				subject { app_class.router.reverse_routes }

				let(:expected_reverse_routes) do
					{
						'ApplicationController' => {
							index: '/application/',
							foo: '/application/foo',
							bar: '/application/bar',
							hello: '/application/hello/:name',
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
					}
				end

				it { is_expected.to eq expected_reverse_routes }
			end
		end

		context 'when controller from the same namespace as application' do
			subject(:mounting) do
				app_class.class_exec do
					mount :nested
				end
			end

			let(:app_class) { Class.new(ApplicationNamespace::Application) }

			it { expect { mounting }.not_to raise_error }
		end

		context 'when controller is anonymous' do
			subject(:mounting) do
				controller = self.controller

				app_class.class_exec do
					mount controller, '/'
				end
			end

			let(:controller) { Class.new(Flame::Controller) }

			it { expect { mounting }.not_to raise_error }
		end

		context 'when controller with refined HTTP-methods inside' do
			before do
				app_class.class_exec do
					mount :application_refined_actions
				end
			end

			let(:expected_routes) do
				{
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
					},
					update: {
						http_method: :PUT,
						action_path: '/module/update'
					}
				}
			end

			it do
				expect(routes).to eq initialize_path_hashes(
					ApplicationRefinedActionsController, **expected_routes
				)
			end
		end

		context 'when controller with refined path inside' do
			before do
				app_class.class_exec do
					mount ApplicationRefinedPathController
				end
			end

			let(:expected_routes) do
				{
					index: {
						ctrl_path: '/that_path_is_refined',
						http_method: :GET
					},
					show: {
						ctrl_path: '/that_path_is_refined',
						http_method: :GET,
						action_path: '/:id'
					}
				}
			end

			it do
				expect(routes).to eq initialize_path_hashes(
					ApplicationRefinedPathController, **expected_routes
				)
			end
		end

		describe 'auto-mount nested controllers' do
			before do
				app_class.class_exec do
					mount :site

					mount :api, nested: false do
						mount :foo
					end
				end
			end

			let(:app_class) { Class.new(ApplicationControllers::Application) }

			let(:expected_result) do
				initialize_path_hashes(
					ApplicationControllers::Site::IndexController, :index, :about
				).deep_merge! initialize_path_hashes(
					ApplicationControllers::Site::PagesController,
					prefix: :site,
					show: { action_path: '/:id' }
				).deep_merge! initialize_path_hashes(
					ApplicationControllers::Site::Cabinet::IndexController, :index,
					prefix: :site
				).deep_merge! initialize_path_hashes(
					ApplicationControllers::Site::Cabinet::SignInController, :index,
					prefix: 'site/cabinet',
					sign_in_post: { http_method: :POST, action_path: '/' }
				).deep_merge! initialize_path_hashes(
					ApplicationControllers::Site::Cabinet::Admin::IndexController, :index,
					prefix: 'site/cabinet'
				).deep_merge! initialize_path_hashes(
					ApplicationControllers::Site::Cabinet::Admin::UsersController,
					:index,
					prefix: 'site/cabinet/admin',
					show: { action_path: '/:id' },
					update: { http_method: :PUT, action_path: '/:id' },
					delete: {
						http_method: :DELETE, action_path: '/:id'
					}
				).deep_merge! initialize_path_hashes(
					ApplicationControllers::API::IndexController, :index, :about
				).deep_merge! initialize_path_hashes(
					ApplicationControllers::API::FooController,
					prefix: :api,
					show: { action_path: '/:id' }
				)
			end

			it { is_expected.to eq expected_result }

			context 'with nonexistent controller name' do
				subject(:mounting) do
					app_class.class_exec do
						mount :nonexistent
					end
				end

				it do
					expect { mounting }.to raise_error(
						Flame::Errors::ControllerNotFoundError,
						"Controller 'nonexistent' not found for 'ApplicationControllers'"
					)
				end
			end
		end
	end
end
