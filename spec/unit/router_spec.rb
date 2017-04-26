# frozen_string_literal: true

## Test controller for Router
class RouterController < Flame::Controller
	def foo(first, second, third = nil); end
end

## Test controller with REST methods for Router
class RouterRESTController < Flame::Controller
	def index; end

	def create; end

	def show(id); end

	def update(id); end

	def delete(id); end
end

def rest_routes(prefix = nil)
	[
		[:index,  :GET,    "#{prefix}/", '/'],
		[:create, :POST,   "#{prefix}/", '/'],
		[:show,   :GET,    "#{prefix}/", ":id"],
		[:update, :PUT,    "#{prefix}/", ":id"],
		[:delete, :DELETE, "#{prefix}/", ":id"]
	].map{ |route| Flame::Router::Route.new(RouterRESTController, *route) }
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
			@router.routes.should.be.instance_of Array
		end
	end

	describe '#initialize' do
		it 'should initialize empty Array of routes' do
			@router.routes.should.be.instance_of Array
			@router.routes.should.be.empty
		end
	end

	describe '#add_controller' do
		it 'should add routes from controller without refinings' do
			@router.add_controller RouterController
			route = Flame::Router::Route.new(
				RouterController, :foo, :GET, '/router/foo/', ':first/:second/:?third'
			)
			@router.routes.should.equal [route]
		end

		it 'should add routes from controller with another path' do
			@router.add_controller RouterController, '/another'
			route = Flame::Router::Route.new(
				RouterController, :foo, :GET, '/another/foo/', ':first/:second/:?third'
			)
			@router.routes.should.equal [route]
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
			route = Flame::Router::Route.new(
				RouterController, :foo, :POST, '/router/foo/', ':first/:second/:?third'
			)
			@router.routes.should.equal [route]
		end

		it 'should mount controller with overwrited action path' do
			@router.add_controller RouterController do
				get '/bar/:first/:second/:?third', :foo
			end
			route = Flame::Router::Route.new(
				RouterController, :foo, :GET, '/router/bar/', ':first/:second/:?third'
			)
			@router.routes.should.equal [route]
		end

		it 'should mount controller with overwrited arguments order' do
			@router.add_controller RouterController do
				get '/foo/:second/:first/:?third', :foo
			end
			route = Flame::Router::Route.new(
				RouterController, :foo, :GET, '/router/foo/', ':second/:first/:?third'
			)
			@router.routes.should.equal [route]
		end

		it 'should mount controller with all of available overwrites' do
			@router.add_controller RouterController do
				post '/bar/:second/:first/:?third', :foo
			end
			route = Flame::Router::Route.new(
				RouterController, :foo, :POST, '/router/bar/', ':second/:first/:?third'
			)
			@router.routes.should.equal [route]
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

		it 'should raise error when at least one required argument is missing' do
			path = '/foo/:first/:?third'
			block = lambda do
				@router.add_controller RouterController do
					post path, :foo
				end
			end
			block.should.raise(Flame::Errors::RouteArgumentsError)
				.message.should match_words(path, 'second')
		end

		it 'should raise error when at least one optional argument is missing' do
			path = '/foo/:first/:second'
			block = lambda do
				@router.add_controller RouterController do
					post path, :foo
				end
			end
			block.should.raise(Flame::Errors::RouteArgumentsError)
				.message.should match_words(path, 'third')
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

		it 'should mount defaults REST actions' do
			@router.add_controller RouterRESTController, '/'
			@router.routes.sort.should.equal rest_routes.sort
		end

		it 'should mount sorted routes' do
			@router.add_controller RouterRESTController, '/'
			@router.routes.should.equal rest_routes.sort
		end

		it 'should overwrite existing routes' do
			@router.add_controller RouterController do
				get :foo
				post :foo
			end
			route = Flame::Router::Route.new(
				RouterController, :foo, :POST, '/router/foo/', ':first/:second/:?third'
			)
			@router.routes.should.equal [route]
		end

		it 'should mount nested controllers' do
			@router.add_controller RouterController do
				mount RouterRESTController, '/rest' do
					mount RouterController
				end
			end
			routes = rest_routes('/router/rest').sort
			routes.unshift(
				Flame::Router::Route.new(
					RouterController, :foo, :GET,
					'/router/rest/router/foo/', ':first/:second/:?third'
				)
			)
			routes.push(
				Flame::Router::Route.new(
					RouterController, :foo, :GET, '/router/foo/', ':first/:second/:?third'
				)
			)
			@router.routes.should.equal routes
		end
	end

	describe '#find_route' do
		it 'should return route by controller and action' do
			@router.add_controller RouterRESTController
			@router.find_route(controller: RouterRESTController, action: :show)
				.should.equal Flame::Router::Route.new(
					RouterRESTController, :show, :GET, '/router_rest', ':id'
				)
		end

		it 'should return route by method and path parts' do
			@router.add_controller RouterRESTController
			@router.find_route(method: :PUT, path_parts: %w[router_rest 42])
				.should.equal Flame::Router::Route.new(
					RouterRESTController, :update, :PUT, '/router_rest', ':id'
				)
		end

		it 'should return route by path parts without optional argument' do
			@router.add_controller RouterController
			@router.find_route(path_parts: %w[router foo bar baz])
				.should.equal Flame::Router::Route.new(
					RouterController, :foo, :GET, '/router/foo/', ':first/:second/:?third'
				)
		end

		it 'should return route by any possible arguments' do
			@router.add_controller RouterRESTController
			@router.find_route(
				controller: RouterRESTController,
				action: :update,
				method: :PUT,
				path_parts: %w[router_rest 42]
			)
				.should.equal Flame::Router::Route.new(
					RouterRESTController, :update, :PUT, '/router_rest', ':id'
				)
		end

		it 'should return nil for not existing route' do
			@router.add_controller RouterRESTController
			@router.find_route(action: :foo)
				.should.equal nil
		end

		it 'should return nil by path parts without required argument' do
			@router.add_controller RouterController
			@router.find_route(path_parts: %w[router foo bar])
				.should.equal nil
		end
	end

	describe '#find_nearest_route' do
		it 'should return route by path parts' do
			@router.add_controller RouterController
			@router.find_nearest_route(%w[router foo bar baz qux])
				.should.equal Flame::Router::Route.new(
					RouterController, :foo, :GET, '/router/foo/', ':first/:second/:?third'
				)
		end

		it 'should return route by path parts' do
			@router.add_controller RouterController
			@router.find_nearest_route(%w[router foo bar baz qux])
				.should.equal Flame::Router::Route.new(
					RouterController, :foo, :GET, '/router/foo/', ':first/:second/:?third'
				)
		end

		it 'should return route by path parts without optional argument' do
			@router.add_controller RouterController
			@router.find_nearest_route(%w[router foo bar baz])
				.should.equal Flame::Router::Route.new(
					RouterController, :foo, :GET, '/router/foo/', ':first/:second/:?third'
				)
		end

		it 'should return nil for not existing route' do
			@router.add_controller RouterController
			@router.find_nearest_route(%w[router bar])
				.should.equal nil
		end

		it 'should return nil by path parts without required argument' do
			@router.add_controller RouterController
			@router.find_nearest_route(%w[router foo bar])
				.should.equal nil
		end
	end
end
