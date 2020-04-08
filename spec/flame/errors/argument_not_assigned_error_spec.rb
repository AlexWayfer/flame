# frozen_string_literal: true

describe Flame::Errors::ArgumentNotAssignedError do
	subject(:error) do
		described_class.new(
			'/foo/:first/:second',
			':second'
		)
	end

	let(:correct_message) do
		"Argument ':second' for path '/foo/:first/:second' is not assigned"
	end

	it_behaves_like 'error with correct output'
end
