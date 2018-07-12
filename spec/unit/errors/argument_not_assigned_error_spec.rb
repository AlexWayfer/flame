# frozen_string_literal: true

describe 'Flame::Errors' do
	describe Flame::Errors::ArgumentNotAssignedError do
		before do
			@error = Flame::Errors::ArgumentNotAssignedError.new(
				'/foo/:first/:second',
				':second'
			)

			@correct_message =
				"Argument ':second' for path '/foo/:first/:second' is not assigned"
		end

		behaves_like 'error with correct output'
	end
end
