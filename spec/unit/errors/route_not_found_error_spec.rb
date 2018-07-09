# frozen_string_literal: true

describe 'Flame::Errors' do
	describe Flame::Errors::RouteNotFoundError do
		subject(:error) do
			Flame::Errors::RouteNotFoundError.new(ErrorsController, :bar)
		end

		let(:correct_message) do
			"Route with controller 'ErrorsController' and action 'bar' " \
				'not found in application routes'
		end

		it_behaves_like 'error with correct output'
	end
end
