# frozen_string_literal: true

## Test controller for Route
class RouteController < Flame::Controller
	def foo(first, second, third = nil, fourth = nil); end

	def bar(first, second, third = nil, fourth = nil); end

	def baz(first, second); end

	def show(id); end

	def export_cards; end
end

class AnotherRouteController < Flame::Controller
	def foo; end

	def bar; end
end

describe Flame::Router::Route do
	before do
		@init = proc do |*args|
			args = [RouteController, :foo] if args.empty?
			Flame::Router::Route.new(*args)
		end
	end

	describe '#initialize' do
		it 'should receive controller and action' do
			-> { @init.call(RouteController, :foo) }
				.should.not.raise(ArgumentError)
		end
	end

	describe '#==' do
		it 'should return true for another object with the same attributes' do
			@init.call.should == @init.call
		end

		it 'should return false for another object with another controller' do
			route = @init.call(RouteController, :foo)
			other = @init.call(AnotherRouteController, :foo)
			route.should.not == other
		end

		it 'should return false for another object with another action' do
			route = @init.call(RouteController, :foo)
			other = @init.call(RouteController, :bar)
			route.should.not == other
		end
	end
end
