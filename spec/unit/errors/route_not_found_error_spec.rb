# frozen_string_literal: true

describe 'Flame::Errors' do
	describe Flame::Errors::RouteNotFoundError do
		before do
			@error = Flame::Errors::RouteNotFoundError.new(ErrorsController, :bar)
		end

		describe '#message' do
			it 'should be correct' do
				@error.message.should.equal(
					"Route with controller 'ErrorsController' and method 'bar'" \
						' not found in application routes'
				)
			end
		end
	end
end
