# frozen_string_literal: true

## Test controller for Validators
class ValidatorsController < Flame::Controller
	def foo(first, second, third = nil); end
end

describe 'Flame::Validators' do
	describe Flame::Validators::RouteArgumentsValidator do
		before do
			@init = proc do |path:|
				Flame::Validators::RouteArgumentsValidator.new(
					ValidatorsController, path, :foo
				)
			end
		end

		describe '#valid?' do
			it 'should return true for no extra arguments' do
				@init.call(path: '/foo/:first/:second/:?third')
					.valid?.should.equal true
			end

			it 'should raise error for extra action required arguments' do
				path = '/foo/:first/:?third'
				-> { @init.call(path: path).valid? }
					.should.raise(Flame::Errors::RouteArgumentsError)
					.message.should.equal(
						"Path '#{path}' has no required arguments [:second]"
					)
			end

			it 'should raise error for extra action optional arguments' do
				path = '/foo/:first/:second'
				-> { @init.call(path: path).valid? }
					.should.raise(Flame::Errors::RouteArgumentsError)
					.message.should.equal(
						"Path '#{path}' has no optional arguments [:third]"
					)
			end

			it 'should raise error for extra path required arguments' do
				-> { @init.call(path: '/foo/:first/:second/:fourth/:?third').valid? }
					.should.raise(Flame::Errors::RouteArgumentsError)
					.message.should.equal(
						"Action 'ValidatorsController#foo'" \
							' has no required arguments [:fourth]'
					)
			end

			it 'should raise error for extra path optional arguments' do
				-> { @init.call(path: '/foo/:first/:second/:?third/:?fourth').valid? }
					.should.raise(Flame::Errors::RouteArgumentsError)
					.message.should.equal(
						"Action 'ValidatorsController#foo'" \
							' has no optional arguments [:fourth]'
					)
			end
		end
	end
end
