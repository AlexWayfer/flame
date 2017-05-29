# frozen_string_literal: true

## Test controller for Route
class RouteController < Flame::Controller
	def foo(first, second, third = nil); end

	def bar(first, second, third = nil); end

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
				args.fetch(:action_path, '/:first/:second/:?third')
			)
		end
	end

	describe '#initialize' do
		it 'should make path parts' do
			@init.call.path_parts.should.equal %w[foo :first :second :?third]
		end

		it 'should clean empty parts from path parts' do
			@init.call(
				ctrl_path: '/foo//',
				action_path: '/:first///:second////:?third/////'
			).path_parts.any?(&:empty?).should.equal false
		end

		it 'should raise error with wrong path arguments' do
			action_path = '/:bar/:baz'
			lambda {
				@init.call(
					ctrl_path: '/foo',
					action_path: action_path
				)
			}
				.should.raise(Flame::Errors::RouteArgumentsError)
				.message.should match_words(action_path, 'first', 'second')
		end

		it 'should raise error without required path arguments' do
			action_path = '/:first'
			lambda {
				@init.call(
					ctrl_path: '/foo',
					action_path: action_path
				)
			}
				.should.raise(Flame::Errors::RouteArgumentsError)
				.message.should match_words(action_path, 'second')
		end

		it 'should raise error with extra required path arguments' do
			lambda {
				@init.call(
					ctrl_path: '/foo',
					action_path: '/:first/:second/:third'
				)
			}
				.should.raise(Flame::Errors::RouteArgumentsError)
				.message.should match_words('RouteController', 'third')
		end

		it 'should raise error with extra optional path arguments' do
			lambda {
				@init.call(
					ctrl_path: '/foo',
					action_path: '/:first/:second/:?third/:?four'
				)
			}
				.should.raise(Flame::Errors::RouteArgumentsError)
				.message.should match_words('RouteController', 'four')
		end
	end

	describe '#freeze' do
		it 'should freeze path' do
			@init.call.path.should.be.frozen
		end

		it 'should freeze path parts' do
			@init.call.path_parts.should.be.frozen
		end
	end

	describe '#compare_attributes' do
		it 'should return true for all correct attributes' do
			attributes = {
				controller: RouteController,
				action: :foo,
				method: :GET,
				path: '/foo/:first/:second/:?third',
				path_parts: %w[foo bar baz bat]
			}
			@init.call.compare_attributes(attributes).should.equal attributes
		end

		it 'should return true for HEAD request instead of GET' do
			attributes = {
				controller: RouteController,
				action: :foo,
				method: :HEAD,
				path: '/foo/:first/:second/:?third',
				path_parts: %w[foo bar baz bat]
			}
			@init.call.compare_attributes(attributes).should.equal attributes
		end

		it 'should return false for HEAD request instead of POST' do
			route = @init.call(method: :POST)
			attributes = {
				controller: RouteController,
				action: :foo,
				method: :HEAD,
				path: '/foo/:first/:second/:?third',
				path_parts: %w[foo bar baz bat]
			}
			route.compare_attributes(attributes).should.equal false
		end

		it 'should return true for path parts with duplicates' do
			route = @init.call(
				action: :foo,
				ctrl_path: '/foo',
				action_path: '/foo/:first/:second/:?third'
			)
			attributes = {
				controller: RouteController,
				action: :foo,
				method: :GET,
				path_parts: %w[foo foo first second]
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
				path: '/foo/:first/:second/:?third',
				path_parts: %w[foo bar baz bat]
			).should.equal false
		end

		it 'should return false for incorrect action' do
			@init.call.compare_attributes(
				controller: RouteController,
				action: :bar,
				method: :GET,
				path: '/foo/:first/:second/:?third',
				path_parts: %w[foo bar baz bat]
			).should.equal false
		end

		it 'should return false for incorrect method' do
			@init.call.compare_attributes(
				controller: RouteController,
				action: :foo,
				method: :POST,
				path: '/foo/:first/:second/:?third',
				path_parts: %w[foo bar baz bat]
			).should.equal false
		end

		it 'should return false for incorrect path' do
			@init.call.compare_attributes(
				controller: RouteController,
				action: :foo,
				method: :GET,
				path: '/foo/:first/:second',
				path_parts: %w[foo bar baz bat]
			).should.equal false
		end

		it 'should return false for incorrect path parts' do
			@init.call.compare_attributes(
				controller: RouteController,
				action: :foo,
				method: :GET,
				path: '/foo/:first/:second/:?third',
				path_parts: %w[foo bar]
			).should.equal false
		end
	end

	describe '#assign_arguments' do
		it 'should assign arguments' do
			@init.call.assign_arguments(
				first: 'bar',
				second: 'baz'
			).should.equal '/foo/bar/baz'
		end

		it 'should not assign arguments without one required' do
			-> { @init.call.assign_arguments(first: 'bar') }
				.should.raise(Flame::Errors::ArgumentNotAssignedError)
				.message.should match_words(':second', '/foo/:first/:second/:?third')
		end
	end

	describe '#arguments' do
		it 'should return arguments from path parts' do
			@init.call.arguments(%w[foo bar baz])
				.should.equal Hash[first: 'bar', second: 'baz']
		end

		it 'should return decoded arguments from path parts' do
			@init.call.arguments(%w[foo another%20bar baz])
				.should.equal Hash[first: 'another bar', second: 'baz']
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

	describe '.path_merge' do
		it 'should merge from array' do
			Flame::Router::Route.path_merge(%w[foo bar baz])
				.should.equal 'foo/bar/baz'
		end

		it 'should merge from multiple parts' do
			Flame::Router::Route.path_merge('/foo/bar', '/baz/bat')
				.should.equal '/foo/bar/baz/bat'
		end

		it 'should merge without extra slashes' do
			Flame::Router::Route.path_merge('///foo/bar//', '//baz/bat///')
				.should.equal '/foo/bar/baz/bat/'
		end
	end
end
