# frozen_string_literal: true

## Test controller for Validators
class ValidatorsController < Flame::Controller
	def foo(first, second, third = nil, fourth = nil); end
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
				@init.call(path: '/foo/:first/:second/:?third/:?fourth')
					.valid?.should.equal true
			end

			it 'should raise error for extra action required arguments' do
				path = '/foo/:first/:?third/:?fourth'
				-> { @init.call(path: path).valid? }
					.should.raise(Flame::Errors::RouteExtraArgumentsError)
					.message.should.equal(
						"Path '#{path}' has no required arguments [:second]"
					)
			end

			it 'should raise error for extra action optional arguments' do
				path = '/foo/:first/:second'
				-> { @init.call(path: path).valid? }
					.should.raise(Flame::Errors::RouteExtraArgumentsError)
					.message.should.equal(
						"Path '#{path}' has no optional arguments [:third, :fourth]"
					)
			end

			it 'should raise error for extra path required arguments' do
				path = '/foo/:first/:second/:fourth/:?third/:?fourth'
				-> { @init.call(path: path).valid? }
					.should.raise(Flame::Errors::RouteExtraArgumentsError)
					.message.should.equal(
						"Action 'ValidatorsController#foo'" \
							' has no required arguments [:fourth]'
					)
			end

			it 'should raise error for extra path optional arguments' do
				path = '/foo/:first/:second/:?third/:?fourth/:?fifth'
				-> { @init.call(path: path).valid? }
					.should.raise(Flame::Errors::RouteExtraArgumentsError)
					.message.should.equal(
						"Action 'ValidatorsController#foo'" \
							' has no optional arguments [:fifth]'
					)
			end

			it 'should raise error for wrong order of optional arguments' do
				path = '/foo/:first/:second/:?fourth/:?third'
				-> { @init.call(path: path).valid? }
					.should.raise(Flame::Errors::RouteArgumentsOrderError)
					.message.should.equal(
						"Path '#{path}' should have ':?third' argument before ':?fourth'"
					)
			end
		end
	end
end
