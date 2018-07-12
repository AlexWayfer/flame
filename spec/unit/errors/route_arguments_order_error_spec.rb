# frozen_string_literal: true

describe 'Flame::Errors' do
	describe Flame::Errors::RouteArgumentsOrderError do
		before do
			path = '/foo/:first/:second/:?fourth/:?third'

			@error =
				Flame::Errors::RouteArgumentsOrderError.new(path, %w[:?third :?fourth])

			@correct_message =
				"Path '#{path}' should have ':?third' argument before ':?fourth'"
		end

		behaves_like 'error with correct output'
	end
end
