# frozen_string_literal: true
## Test controller for Route
class RouteController < Flame::Controller
	def foo(first, second, third = nil); end
end

describe Flame::Router::Route do
	before do
		@init = proc do |path: '/foo/:first/:second/:?third'|
			Flame::Router::Route.new(RouteController, :foo, :GET, path)
		end
	end

	describe '#initialize' do
		it 'should make path parts' do
			@init.call.path_parts.should.equal %w(foo :first :second :?third)
		end

		it 'should clean empty parts from path parts' do
			@init.call(path: '/foo//:first///:second////:?third/////')
				.path_parts.any?(&:empty?).should.equal false
		end

		it 'should raise error with incorrect path arguments' do
			%w(
				/foo/:bar/:baz
				/foo/:first
				/foo/:first/:second/:third
				/foo/:first/:second/:?third/:?four
			).each do |path|
				-> { @init.call(path: path) }
					.should.raise(Flame::Errors::RouterError::RouteArgumentsError)
					.message.should.not.be.empty
			end
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
				path_parts: %w(foo bar baz bat)
			}
			@init.call.compare_attributes(attributes).should.equal attributes
		end

		it 'should return false for incorrect controller' do
			@init.call.compare_attributes(
				controller: Flame::Controller,
				action: :foo,
				method: :GET,
				path: '/foo/:first/:second/:?third',
				path_parts: %w(foo bar baz bat)
			).should.equal false
		end

		it 'should return false for incorrect action' do
			@init.call.compare_attributes(
				controller: RouteController,
				action: :bar,
				method: :GET,
				path: '/foo/:first/:second/:?third',
				path_parts: %w(foo bar baz bat)
			).should.equal false
		end

		it 'should return false for incorrect method' do
			@init.call.compare_attributes(
				controller: RouteController,
				action: :foo,
				method: :POST,
				path: '/foo/:first/:second/:?third',
				path_parts: %w(foo bar baz bat)
			).should.equal false
		end

		it 'should return false for incorrect path' do
			@init.call.compare_attributes(
				controller: RouteController,
				action: :foo,
				method: :GET,
				path: '/foo/:first/:second',
				path_parts: %w(foo bar baz bat)
			).should.equal false
		end

		it 'should return false for incorrect path parts' do
			@init.call.compare_attributes(
				controller: RouteController,
				action: :foo,
				method: :GET,
				path: '/foo/:first/:second/:?third',
				path_parts: %w(foo bar)
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
		end
	end

	describe '#arguments' do
		it 'should return arguments from path parts' do
			@init.call.arguments(%w(foo bar baz))
				.should.equal Hash[first: 'bar', second: 'baz']
		end

		it 'should return decoded arguments from path parts' do
			@init.call.arguments(%w(foo another%20bar baz))
				.should.equal Hash[first: 'another bar', second: 'baz']
		end
	end

	describe '.path_merge' do
		it 'should merge from array' do
			Flame::Router::Route.path_merge(%w(foo bar baz))
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
