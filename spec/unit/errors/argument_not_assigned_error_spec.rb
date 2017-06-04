# frozen_string_literal: true

describe 'Flame::Errors' do
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
