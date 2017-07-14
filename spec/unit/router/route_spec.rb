# frozen_string_literal: true

## Test controller for Route
class RouteController < Flame::Controller
	def foo(first, second, third = nil, fourth = nil); end

	def bar(first, second, third = nil, fourth = nil); end

	def baz(first, second); end

	def show(id); end

	def export_cards; end
end

describe Flame::Router::Route do
	before do
		@init = proc do |args = {}|
			Flame::Router::Route.new(
				RouteController,
				args.fetch(:action,      :foo),
				args.fetch(:method,      :GET),
				args.fetch(:ctrl_path,   '/foo'),
				args.fetch(:action_path, '/:first/:second/:?third/:?fourth')
			)
		end
	end

	describe '#initialize' do
		it 'should make path' do
			route = @init.call
			route.path.should.be.kind_of Flame::Path
			route.path.should.equal '/foo/:first/:second/:?third/:?fourth'
		end

		it 'should raise error with extra required path arguments' do
			lambda {
				@init.call(
					ctrl_path: '/foo',
					action_path: '/:first/:second/:third'
				)
			}
				.should.raise(Flame::Errors::RouteExtraArgumentsError)
				.message.should match_words('RouteController', 'third')
		end

		it 'should raise error with extra optional path arguments' do
			lambda {
				@init.call(
					ctrl_path: '/foo',
					action_path: '/:first/:second/:?third/:?fourth/:?fifth'
				)
			}
				.should.raise(Flame::Errors::RouteExtraArgumentsError)
				.message.should match_words('RouteController', 'fifth')
		end

		it 'should raise error for wrong order of optional arguments' do
			lambda {
				@init.call(
					ctrl_path: '/foo',
					action_path: '/:first/:second/:?fourth/:?third'
				)
			}
				.should.raise(Flame::Errors::RouteArgumentsOrderError)
				.message.should match_words(
					"'/:first/:second/:?fourth/:?third'", "third", "fourth"
				)
		end
	end

	describe '#freeze' do
		it 'should freeze path' do
			@init.call.path.should.be.frozen
		end
	end

	describe '#compare_attributes' do
		it 'should return true for all correct attributes' do
			attributes = {
				controller: RouteController,
				action: :foo,
				method: :GET,
				path: '/foo/first/second/third'
			}
			@init.call.compare_attributes(attributes).should.equal attributes
		end

		it 'should return true for HEAD request instead of GET' do
			attributes = {
				controller: RouteController,
				action: :foo,
				method: :HEAD,
				path: '/foo/first/second/third'
			}
			@init.call.compare_attributes(attributes).should.equal attributes
		end

		it 'should return false for HEAD request instead of POST' do
			route = @init.call(method: :POST)
			attributes = {
				controller: RouteController,
				action: :foo,
				method: :HEAD,
				path: '/foo/first/second/third'
			}
			route.compare_attributes(attributes).should.equal false
		end

		it 'should return true for path with duplicates parts' do
			route = @init.call(
				action: :foo,
				ctrl_path: '/foo',
				action_path: '/foo/:first/:second/:?third'
			)
			attributes = {
				controller: RouteController,
				action: :foo,
				method: :GET,
				path: '/foo/foo/first/second/third'
			}
			route.compare_attributes(attributes).should.equal attributes
		end

		it 'should return true for downcased method' do
			attributes = {
				controller: RouteController,
				action: :foo,
				method: :get
			}
			@init.call.compare_attributes(attributes).should.equal attributes
		end

		it 'should return true for downcased HEAD request instead of GET' do
			attributes = {
				controller: RouteController,
				action: :foo,
				method: :head
			}
			@init.call.compare_attributes(attributes).should.equal attributes
		end

		it 'should return false for incorrect controller' do
			@init.call.compare_attributes(
				controller: Flame::Controller,
				action: :foo,
				method: :GET,
				path: '/foo/first/second/third'
			).should.equal false
		end

		it 'should return false for incorrect action' do
			@init.call.compare_attributes(
				controller: RouteController,
				action: :bar,
				method: :GET,
				path: '/foo/first/second/third'
			).should.equal false
		end

		it 'should return false for incorrect method' do
			@init.call.compare_attributes(
				controller: RouteController,
				action: :foo,
				method: :POST,
				path: '/foo/first/second/third'
			).should.equal false
		end

		it 'should return false for incorrect path' do
			@init.call.compare_attributes(
				controller: RouteController,
				action: :foo,
				method: :GET,
				path: '/foo/bar'
			).should.equal false
		end
	end

	describe '#==' do
		it 'should return true for another object with the same attributes' do
			@init.call.should.equal @init.call
		end

		it 'should return true for another object with different slashes in path' do
			other = @init.call(
				ctrl_path: '/foo',
				action_path: '/:first////:second/:?third//'
			)
			@init.call.should.equal other
		end

		it 'should return false for another object with another attributes' do
			other = @init.call(
				ctrl_path: '/foo',
				action_path: '/:second/:first/:?third'
			)
			@init.call.should.not.equal other
		end
	end

	describe '#<=>' do
		it 'should return -1 for other route with less count of path parts' do
			(@init.call <=> @init.call(
				action: :baz,
				ctrl_path: '/baz',
				action_path: '/:first/:second'
			))
				.should.equal(-1)
		end

		it 'should return 1 for other route with greater count of path parts' do
			(@init.call(
				action: :baz,
				ctrl_path: '/baz',
				action_path: '/:first/:second'
			) <=> @init.call)
				.should.equal 1
		end

		it 'should return 0 for other route with equal count of path parts' do
			bar_route = @init.call(
				action: :bar,
				ctrl_path: '/bar',
				action_path: '/:first/:second/:?third'
			)
			(@init.call <=> bar_route)
				.should.equal 0
		end

		it 'should return -1 for other route with arguments' do
			export_route = @init.call(
				action: :export_cards,
				ctrl_path: '/route',
				action_path: '/export_cards'
			)
			show_route = @init.call(
				action: :show,
				ctrl_path: '/route',
				action_path: '/:id'
			)
			(export_route <=> show_route)
				.should.equal(-1)
		end
	end
end
