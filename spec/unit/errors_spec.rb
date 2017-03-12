# frozen_string_literal: true
## Test controller for Errors
class ErrorsController < Flame::Controller
	def foo(first, second, third = nil); end
end

describe 'Flame::Errors' do
	describe Flame::Errors::RouterError::RouteArgumentsError do
		before do
			@init = proc do |path:, extra:|
				Flame::Errors::RouterError::RouteArgumentsError.new(
					ErrorsController, :foo, path, extra
				)
			end
		end

		describe '#message' do
			it 'should be correct for extra action required arguments' do
				@init.call(
					path: '/foo/:first/:?third',
					extra: { place: :ctrl, type: :req, args: [:second] }
				).message.should.equal(
					"Path '/foo/:first/:?third' has no required arguments [:second]"
				)
			end

			it 'should be correct for extra action optional arguments' do
				@init.call(
					path: '/foo/:first/:second',
					extra: { place: :ctrl, type: :opt, args: [:third] }
				).message.should.equal(
					"Path '/foo/:first/:second' has no optional arguments [:third]"
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
end
