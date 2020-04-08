# frozen_string_literal: true

describe Flame::Errors::RouteArgumentsOrderError do
	subject(:error) do
		described_class.new(path, %w[:?third :?fourth])
	end

	let(:path) { '/foo/:first/:second/:?fourth/:?third' }

	let(:correct_message) do
		"Path '#{path}' should have ':?third' argument before ':?fourth'"
	end

	it_behaves_like 'error with correct output'
end
