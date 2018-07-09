# frozen_string_literal: true

describe 'Flame::Errors' do
	describe Flame::Errors::RouteArgumentsOrderError do
		let(:path) { '/foo/:first/:second/:?fourth/:?third' }

		subject(:error) do
			described_class.new(path, %w[:?third :?fourth])
		end

		let(:correct_message) do
			"Path '#{path}' should have ':?third' argument before ':?fourth'"
		end

		it_behaves_like 'error with correct output'
	end
end
