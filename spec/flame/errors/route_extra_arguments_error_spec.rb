# frozen_string_literal: true

describe Flame::Errors::RouteExtraArgumentsError do
	subject(:error) { described_class.new(ErrorsController, :foo, path, extra) }

	context 'when extra action required arguments' do
		let(:path) { '/foo/:first/:?third/:?fourth' }
		let(:extra) { { place: :ctrl, type: :req, args: [:second] } }

		let(:correct_message) do
			"Path '#{path}' has no required arguments [:second]"
		end

		it_behaves_like 'error with correct output'
	end

	context 'when extra action optional arguments' do
		let(:path) { '/foo/:first/:second' }
		let(:extra) { { place: :ctrl, type: :opt, args: [:third] } }

		let(:correct_message) do
			"Path '#{path}' has no optional arguments [:third]"
		end

		it_behaves_like 'error with correct output'
	end

	context 'when extra path required arguments' do
		let(:path) { '/foo/:first/:second/:third' }
		let(:extra) { { place: :path, type: :req, args: [:third] } }

		let(:correct_message) do
			"Action 'ErrorsController#foo' has no required arguments [:third]"
		end

		it_behaves_like 'error with correct output'
	end

	context 'when extra path optional arguments' do
		let(:path) { '/foo/:first/:second/:?third/:?fourth/:?fifth' }
		let(:extra) { { place: :path, type: :opt, args: [:fifth] } }

		let(:correct_message) do
			"Action 'ErrorsController#foo' has no optional arguments [:fifth]"
		end

		it_behaves_like 'error with correct output'
	end
end
