# frozen_string_literal: true

describe 'Flame::Errors' do
	describe Flame::Errors::RouteNotFoundError do
		before do
			@error = Flame::Errors::RouteNotFoundError.new(ErrorsController, :bar)

			@correct_message =
				"Route with controller 'ErrorsController' and action 'bar' " \
					'not found in application routes'
		end

		behaves_like 'error with correct output'
	end
end
