# frozen_string_literal: true

## Test controller for Validators
class ValidatorsController < Flame::Controller
	def foo(first, second, third = nil, fourth = nil); end
end

describe Flame::Validators do
	describe Flame::Validators::RouteArgumentsValidator do
		subject(:validator) do
			described_class.new(ValidatorsController, path, :foo)
		end

		describe '#valid?' do
			subject(:result) { validator.valid? }

			context 'when no extra arguments' do
				let(:path) { '/foo/:first/:second/:?third/:?fourth' }

				it { is_expected.to be true }
			end

			context 'when extra action required arguments' do
				let(:path) { '/foo/:first/:?third/:?fourth' }

				it do
					expect { result }.to raise_error(
						Flame::Errors::RouteExtraArgumentsError,
						"Path '#{path}' has no required arguments [:second]"
					)
				end
			end

			context 'when extra action optional arguments' do
				let(:path) { '/foo/:first/:second' }

				it do
					expect { result }.to raise_error(
						Flame::Errors::RouteExtraArgumentsError,
						"Path '#{path}' has no optional arguments [:third, :fourth]"
					)
				end
			end

			context 'when extra path required arguments' do
				let(:path) { '/foo/:first/:second/:fourth/:?third/:?fourth' }

				it do
					expect { result }.to raise_error(
						Flame::Errors::RouteExtraArgumentsError,
						"Action 'ValidatorsController#foo' has no required arguments [:fourth]"
					)
				end
			end

			context 'when extra path optional arguments' do
				let(:path) { '/foo/:first/:second/:?third/:?fourth/:?fifth' }

				it do
					expect { result }.to raise_error(
						Flame::Errors::RouteExtraArgumentsError,
						"Action 'ValidatorsController#foo' has no optional arguments [:fifth]"
					)
				end
			end

			context 'when wrong order of optional arguments' do
				let(:path) { '/foo/:first/:second/:?fourth/:?third' }

				it do
					expect { result }.to raise_error(
						Flame::Errors::RouteArgumentsOrderError,
						"Path '#{path}' should have ':?third' argument before ':?fourth'"
					)
				end
			end
		end
	end
end
