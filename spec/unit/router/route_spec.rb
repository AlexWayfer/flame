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
	def route_intialize(*args)
		Flame::Router::Route.new(*args)
	end

	subject(:route) { route_intialize(*args) }

	let(:args) { [RouteController, :foo] }

	describe '#initialize' do
		it 'receives controller and action' do
			expect { subject }.not_to raise_error
		end
	end

	describe '#==' do
		subject { left == right }

		let(:left)  { route_intialize(*left_args) }
		let(:right) { route_intialize(*right_args) }

		context 'another object with the same attributes' do
			let(:left_args)  { args }
			let(:right_args) { left_args }

			it { is_expected.to be true }
		end

		context 'another object with another controller' do
			let(:left_args)  { [RouteController, :foo] }
			let(:right_args) { [AnotherRouteController, :foo] }

			it { is_expected.to be false }
		end

		context 'another object with another action' do
			let(:left_args)  { [RouteController, :foo] }
			let(:right_args) { [RouteController, :bar] }

			it { is_expected.to be false }
		end
	end
end
