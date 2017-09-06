# frozen_string_literal: true

require 'gorilla-patch/deep_merge'

using GorillaPatch::DeepMerge

## Test controller for Router
class RouterController < Flame::Controller
	def index; end

	def foo(first, second, third = nil, fourth = nil); end
end

## Test controller with REST methods for Router
class RouterRESTController < Flame::Controller
	def index; end

	def create; end

	def show(id); end

	def update(id); end

	def delete(id); end
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
	Flame::Router::Route.new(RouterRESTController, action)
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

class RouterApplication < Flame::Application
end

describe Flame::Router do
	before do
		@router = Flame::Router.new(RouterApplication)
	end

	describe 'attrs' do
		it 'should have app reader' do
			@router.app.should < Flame::Application
		end

		it 'should have routes reader' do
			@router.routes.should.be.instance_of Flame::Router::Routes
		end

		it 'should have reverse_routes reader' do
			@router.reverse_routes.should.be.instance_of Hash
		end
	end

	describe '#initialize' do
		it 'should initialize empty routes' do
			@router.routes.should.be.instance_of Flame::Router::Routes
			@router.routes.should.be.empty
		end

		it 'should initialize empty Hash of reverse_routes' do
			@router.reverse_routes.should.be.instance_of Hash
			@router.reverse_routes.should.be.empty
		end
	end

	describe '#add_controller' do
		it 'should add routes from controller without refinings' do
			@router.add_controller RouterController

			@router.routes.should.equal initialize_path_hashes(
				RouterController, :index, :foo
			)
		end

		it 'should add routes from controller with another path' do
			@router.add_controller RouterController, '/another'

			@router.routes.should.equal initialize_path_hashes(
				RouterController,
				index: { ctrl_path: '/another' },
				foo:   { ctrl_path: '/another' }
			)
		end

		it 'should add routes from controller with refining block' do
			@router.add_controller RouterController do
			end

			@router.routes.should.be.any
		end

		it 'should mount controller with overwrited HTTP-methods' do
			@router.add_controller RouterController do
				post '/foo/:first/:second/:?third', :foo
			end

			@router.routes.should.equal initialize_path_hashes(
				RouterController, :index, foo: { http_method: :POST }
			)
		end

		it 'should mount controller with overwrited action path' do
			@router.add_controller RouterController do
				get '/bar/:first/:second/:?third/:?fourth', :foo
			end

			@router.routes.should.equal initialize_path_hashes(
				RouterController, :index, foo: { action_path: '/bar' }
			)
		end

		it 'should mount controller with overwrited arguments order' do
			@router.add_controller RouterController do
				get '/foo/:second/:first/:?third/:?fourth', :foo
			end

			@router.routes.should.equal initialize_path_hashes(
				RouterController,
				:index,
				foo: { action_path: '/foo/:second/:first/:?third/:?fourth' }
			)
		end

		it 'should mount controller with all of available overwrites' do
			@router.add_controller RouterController do
				post '/bar/:second/:first/:?third/:?fourth', :foo
			end

			@router.routes.should.equal initialize_path_hashes(
				RouterController,
				:index,
				foo: {
					action_path: '/bar/:second/:first/:?third/:?fourth',
					http_method: :POST
				}
			)
		end

		it 'should mount controller without arguments' do
			@router.add_controller RouterController do
				post '/bar', :foo
			end

			@router.routes.should.equal initialize_path_hashes(
				RouterController,
				:index,
				foo: {
					action_path: '/bar/:first/:second/:?third/:?fourth',
					http_method: :POST
				}
			)
		end

		it 'should mount controller when required arguments are missing' do
			@router.add_controller RouterController do
				post '/bar/:second', :foo
			end

			@router.routes.should.equal initialize_path_hashes(
				RouterController,
				:index,
				foo: {
					action_path: '/bar/:second/:first/:?third/:?fourth',
					http_method: :POST
				}
			)
		end

		it 'should mount controller when optional arguments are missing' do
			@router.add_controller RouterController do
				post '/bar/:second/:first', :foo
			end

			@router.routes.should.equal initialize_path_hashes(
				RouterController,
				:index,
				foo: {
					action_path: '/bar/:second/:first/:?third/:?fourth',
					http_method: :POST
				}
			)
		end

		it 'should raise error when method does not exist' do
			block = lambda do
				@router.add_controller RouterController do
					post :bar
				end
			end
			block.should.raise(NameError)
				.message.should match_words('bar', 'RouterController')
		end

		it 'should raise error when wrong HTTP-method used' do
			block = lambda do
				@router.add_controller RouterController do
					wrong :foo
				end
			end
			block.should.raise(NoMethodError)
				.message.should match_words('wrong')
		end

		it 'should raise error with extra required path arguments' do
			block = lambda do
				@router.add_controller RouterController do
					get '/foo/:first/:second/:third', :foo
				end
			end
			block.should.raise(Flame::Errors::RouteExtraArgumentsError)
				.message.should match_words('RouterController', 'third')
		end

		it 'should raise error with extra optional path arguments' do
			block = lambda do
				@router.add_controller RouterController do
					get '/foo/:first/:second/:?third/:?fourth/:?fifth', :foo
				end
			end
			block.should.raise(Flame::Errors::RouteExtraArgumentsError)
				.message.should match_words('RouterController', 'fifth')
		end

		it 'should raise error for wrong order of optional arguments' do
			block = lambda do
				@router.add_controller RouterController do
					get '/foo/:first/:second/:?fourth/:?third', :foo
				end
			end
			block.should.raise(Flame::Errors::RouteArgumentsOrderError)
				.message.should match_words(
					"'/foo/:first/:second/:?fourth/:?third'", "':?third'", "':?fourth'"
				)
		end

		it 'should mount defaults REST actions' do
			@router.add_controller RouterRESTController, '/'
			@router.routes.should.equal rest_routes
		end

		it 'should overwrite existing routes' do
			@router.add_controller RouterController do
				get :foo
				post :foo
			end

			@router.routes.should.equal initialize_path_hashes(
				RouterController, :index, foo: { http_method: :POST }
			)
		end

		it 'should mount nested controllers' do
			@router.add_controller RouterController do
				mount RouterRESTController, '/rest'
			end

			@router.routes.should.equal rest_routes('/router/rest').deep_merge!(
				initialize_path_hashes(RouterController, :index, :foo)
			)
		end
	end

	describe '#find_nearest_route' do
		it 'should return route by path' do
			@router.add_controller RouterController

			path = Flame::Path.new('/router/foo/bar/baz/qux')
			@router.find_nearest_route(path)
				.should.equal Flame::Router::Route.new(
					RouterController, :foo
				)
		end

		it 'should return root route if there is no such actions' do
			@router.add_controller RouterController

			path = Flame::Path.new('/router/bar')
			@router.find_nearest_route(path)
				.should.equal Flame::Router::Route.new(
					RouterController, :index
				)
		end

		it 'should return root route for controller with nested controller' do
			@router.add_controller RouterController do
				mount RouterRESTController
			end

			path = Flame::Path.new('/router/foo')
			@router.find_nearest_route(path)
				.should.equal Flame::Router::Route.new(
					RouterController, :index
				)
		end

		it 'should return route by path parts without optional argument' do
			@router.add_controller RouterController

			path = Flame::Path.new('/router/foo/bar/baz')
			@router.find_nearest_route(path)
				.should.equal Flame::Router::Route.new(
					RouterController, :foo
				)
		end

		it 'should return nil for not existing route' do
			@router.add_controller RouterController

			path = Flame::Path.new('/another')
			@router.find_nearest_route(path)
				.should.equal nil
		end

		it 'should not return route by path parts without required argument' do
			@router.add_controller RouterController

			path = Flame::Path.new('/router/foo/bar')
			@router.find_nearest_route(path)
				.should.not.equal Flame::Router::Route.new(
					RouterController, :foo
				)
		end
	end

	describe '#path_of' do
		it 'should return path of existing route' do
			route = Flame::Router::Route.new(RouterController, :foo)
			@router.add_controller RouterController
			@router.path_of(route).should.equal(
				'/router/foo/:first/:second/:?third/:?fourth'
			)
		end

		it 'should return path of existing route by controller and action' do
			@router.add_controller RouterController
			@router.path_of(RouterController, :foo).should.equal(
				'/router/foo/:first/:second/:?third/:?fourth'
			)
		end

		it 'should return nil for non-existing route' do
			route = Flame::Router::Route.new(RouterRESTController, :index)
			@router.add_controller RouterController
			@router.path_of(route).should.be.nil
		end
	end
end
