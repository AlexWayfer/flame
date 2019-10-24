# frozen_string_literal: true

module RouterTest
	## Test controller for Router
	class OneController < Flame::Controller
		def index; end

		def foo(first, second, third = nil, fourth = nil); end
	end

	## Another test controller for Router
	class AnotherOneController < Flame::Controller
		def index; end
	end

	class Application < Flame::Application
	end
end

describe Flame::Router do
	subject(:router) { Class.new(RouterTest::Application).router }

	describe '#app' do
		subject { super().app }

		it { is_expected.to be < Flame::Application }
	end

	describe '#routes' do
		subject { super().routes }

		it { is_expected.to be_instance_of Flame::Router::Routes }
	end

	describe '#reverse_routes' do
		subject { super().reverse_routes }

		it { is_expected.to be_instance_of Hash }
	end

	describe '#initialize' do
		describe '#routes' do
			subject { super().routes }

			it { is_expected.to be_instance_of Flame::Router::Routes }
			it { is_expected.to be_empty }
		end

		describe '#reverse_routes' do
			subject { super().reverse_routes }

			it { is_expected.to be_instance_of Hash }
			it { is_expected.to be_empty }
		end
	end

	describe '#find_nearest_route' do
		subject { super().find_nearest_route(path) }

		context 'one mounted controller' do
			before do
				router.app.class_exec do
					mount :one
				end
			end

			context 'existing controller and action' do
				let(:path) { Flame::Path.new('/one/foo/bar/baz/qux') }

				it do
					is_expected.to eq Flame::Router::Route.new(
						RouterTest::OneController, :foo
					)
				end
			end

			context 'nonexistent action' do
				let(:path) { Flame::Path.new('/one/not_exist') }

				it do
					is_expected.to eq Flame::Router::Route.new(
						RouterTest::OneController, :index
					)
				end
			end

			context 'path without optional argument' do
				let(:path) { Flame::Path.new('/one/foo/bar/baz') }

				it do
					is_expected.to eq Flame::Router::Route.new(
						RouterTest::OneController, :foo
					)
				end
			end

			context 'nonexistent route' do
				let(:path) { Flame::Path.new('/another') }

				it do
					is_expected.to be_nil
				end
			end

			context 'path without required argument' do
				let(:path) { Flame::Path.new('/one/foo/bar') }

				it do
					is_expected.not_to eq Flame::Router::Route.new(
						RouterTest::OneController, :foo
					)
				end
			end
		end

		context 'controller with nested controller' do
			let(:path) { Flame::Path.new('/one/foo') }

			before do
				router.app.class_exec do
					mount :one do
						mount :another_one
					end
				end
			end

			it do
				is_expected.to eq Flame::Router::Route.new(
					RouterTest::OneController, :index
				)
			end
		end
	end

	describe '#path_of' do
		subject { super().path_of(*args) }

		before do
			router.app.class_exec do
				mount :one
			end
		end

		context 'existing route' do
			shared_examples 'route found' do
				it { is_expected.to eq '/one/foo/:first/:second/:?third/:?fourth' }
			end

			context 'by route' do
				let(:args) { Flame::Router::Route.new(RouterTest::OneController, :foo) }

				it_behaves_like 'route found'
			end

			context 'by controller and action' do
				let(:args) { [RouterTest::OneController, :foo] }

				it_behaves_like 'route found'
			end
		end

		context 'nonexistent route' do
			let(:args) do
				Flame::Router::Route.new(RouterTest::AnotherOneController, :index)
			end

			it { is_expected.to be_nil }
		end
	end
end
