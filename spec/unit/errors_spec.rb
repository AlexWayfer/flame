# frozen_string_literal: true
## Test controller for Errors
class ErrorsController < Flame::Controller
	def foo(first, second, third = nil); end
end

describe 'Flame::Errors' do
	describe Flame::Errors::RouteArgumentsError do
		before do
			@init = proc do |path:, extra:|
				Flame::Errors::RouteArgumentsError.new(
					ErrorsController, :foo, path, extra
				)
			end
		end

		describe '#message' do
			it 'should be correct for extra action required arguments' do
				path = '/foo/:first/:?third'
				@init.call(
					path: path,
					extra: { place: :ctrl, type: :req, args: [:second] }
				).message.should.equal(
					"Path '#{path}' has no required arguments [:second]"
				)
			end

			it 'should be correct for extra action optional arguments' do
				path = '/foo/:first/:second'
				@init.call(
					path: path,
					extra: { place: :ctrl, type: :opt, args: [:third] }
				).message.should.equal(
					"Path '#{path}' has no optional arguments [:third]"
				)
			end

			it 'should be correct for extra path required arguments' do
				@init.call(
					path: '/foo/:first/:second/:third',
					extra: { place: :path, type: :req, args: [:third] }
				).message.should.equal(
					"Action 'ErrorsController#foo' has no required arguments [:third]"
				)
			end

			it 'should be correct for extra path optional arguments' do
				@init.call(
					path: '/foo/:first/:second/:?third/:?fourth',
					extra: { place: :path, type: :opt, args: [:fourth] }
				).message.should.equal(
					"Action 'ErrorsController#foo' has no optional arguments [:fourth]"
				)
			end
		end
	end

	describe Flame::Errors::RouteNotFoundError do
		before do
			@error = Flame::Errors::RouteNotFoundError.new(ErrorsController, :bar)
		end

		describe '#message' do
			it 'should be correct' do
				@error.message.should.equal(
					"Route with controller 'ErrorsController' and method 'bar'" \
						' not found in application routes'
				)
			end
		end
	end

	describe Flame::Errors::ArgumentNotAssignedError do
		before do
			@error = Flame::Errors::ArgumentNotAssignedError.new(
				'/foo/:first/:second',
				':second'
			)
		end

		describe '#message' do
			it 'should be correct' do
				@error.message.should.equal(
					"Argument ':second' for path '/foo/:first/:second' is not assigned"
				)
			end
		end
	end
end
