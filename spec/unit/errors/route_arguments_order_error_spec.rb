# frozen_string_literal: true

describe 'Flame::Errors' do
	describe Flame::Errors::RouteArgumentsOrderError do
		before do
			@init = proc do |path:, wrong_ordered_arguments:|
				Flame::Errors::RouteArgumentsOrderError.new(
					path, wrong_ordered_arguments
				)
			end
		end

		describe '#message' do
			it 'should be correct for wrong order of optional arguments' do
				path = '/foo/:first/:second/:?fourth/:?third'
				@init.call(
					path: path,
					wrong_ordered_arguments: %w[:?third :?fourth]
				).message.should.equal(
					"Path '#{path}' should have ':?third' argument before ':?fourth'"
				)
			end
		end
	end
end
