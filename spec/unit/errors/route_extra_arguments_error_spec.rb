# frozen_string_literal: true

describe 'Flame::Errors' do
	describe Flame::Errors::RouteExtraArgumentsError do
		before do
			@init = proc do |path:, extra:|
				Flame::Errors::RouteExtraArgumentsError.new(
					ErrorsController, :foo, path, extra
				)
			end
		end

		describe 'extra action required arguments' do
			before do
				path = '/foo/:first/:?third/:?fourth'

				@error = @init.call(
					path: path,
					extra: { place: :ctrl, type: :req, args: [:second] }
				)

				@correct_message = "Path '#{path}' has no required arguments [:second]"
			end

			behaves_like 'error with correct output'
		end

		describe 'extra action optional arguments' do
			before do
				path = '/foo/:first/:second'

				@error = @init.call(
					path: path,
					extra: { place: :ctrl, type: :opt, args: [:third] }
				)

				@correct_message = "Path '#{path}' has no optional arguments [:third]"
			end

			behaves_like 'error with correct output'
		end

		describe 'extra path required arguments' do
			before do
				@error = @init.call(
					path: '/foo/:first/:second/:third',
					extra: { place: :path, type: :req, args: [:third] }
				)

				@correct_message =
					"Action 'ErrorsController#foo' has no required arguments [:third]"
			end

			behaves_like 'error with correct output'
		end

		describe 'extra path optional arguments' do
			before do
				@error = @init.call(
					path: '/foo/:first/:second/:?third/:?fourth/:?fifth',
					extra: { place: :path, type: :opt, args: [:fifth] }
				)

				@correct_message =
					"Action 'ErrorsController#foo' has no optional arguments [:fifth]"
			end

			behaves_like 'error with correct output'
		end
	end
end
