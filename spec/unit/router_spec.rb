# frozen_string_literal: true

## Test controller for Router
class RouterController < Flame::Controller
	def index; end

	def foo(first, second, third = nil, fourth = nil); end
end

## Another test controller for Router
class RouterAnotherController < Flame::Controller
	def index; end
end

class RouterApplication < Flame::Application
end

describe Flame::Router do
	before do
		@app_class = Class.new(RouterApplication)
		@router = @app_class.router
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

	describe '#find_nearest_route' do
		it 'should return route by path' do
			@router.app.class_exec do
				mount :router
			end

			path = Flame::Path.new('/router/foo/bar/baz/qux')
			@router.find_nearest_route(path)
				.should.equal Flame::Router::Route.new(
					RouterController, :foo
				)
		end

		it 'should return root route if there is no such actions' do
			@router.app.class_exec do
				mount :router
			end

			path = Flame::Path.new('/router/bar')
			@router.find_nearest_route(path)
				.should.equal Flame::Router::Route.new(
					RouterController, :index
				)
		end

		it 'should return root route for controller with nested controller' do
			@router.app.class_exec do
				mount :router do
					mount :router_another
				end
			end

			path = Flame::Path.new('/router/foo')
			@router.find_nearest_route(path)
				.should.equal Flame::Router::Route.new(
					RouterController, :index
				)
		end

		it 'should return route by path parts without optional argument' do
			@router.app.class_exec do
				mount :router
			end

			path = Flame::Path.new('/router/foo/bar/baz')
			@router.find_nearest_route(path)
				.should.equal Flame::Router::Route.new(
					RouterController, :foo
				)
		end

		it 'should return nil for not existing route' do
			@router.app.class_exec do
				mount :router
			end

			path = Flame::Path.new('/another')
			@router.find_nearest_route(path)
				.should.equal nil
		end

		it 'should not return route by path parts without required argument' do
			@router.app.class_exec do
				mount :router
			end

			path = Flame::Path.new('/router/foo/bar')
			@router.find_nearest_route(path)
				.should.not.equal Flame::Router::Route.new(
					RouterController, :foo
				)
		end
	end

	describe '#path_of' do
		it 'should return path of existing route' do
			@router.app.class_exec do
				mount :router
			end

			route = Flame::Router::Route.new(RouterController, :foo)
			@router.path_of(route).should.equal(
				'/router/foo/:first/:second/:?third/:?fourth'
			)
		end

		it 'should return path of existing route by controller and action' do
			@router.app.class_exec do
				mount :router
			end

			@router.path_of(RouterController, :foo).should.equal(
				'/router/foo/:first/:second/:?third/:?fourth'
			)
		end

		it 'should return nil for non-existing route' do
			@router.app.class_exec do
				mount :router
			end

			route = Flame::Router::Route.new(RouterAnotherController, :index)
			@router.path_of(route).should.be.nil
		end
	end
end
