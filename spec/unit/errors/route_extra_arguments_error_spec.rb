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

		describe '#message' do
			it 'should be correct for extra action required arguments' do
				path = '/foo/:first/:?third/:?fourth'
				@init.call(
					path: path,
					extra: { place: :ctrl, type: :req, args: [:second] }
				).message.should.equal(
					"Path '#{path}' has no required arguments [:second]"
				)
			end

			it 'should be correct for extra action optional arguments' do
				path = '/foo/:first/:second'
				@init.call(
					path: path,
					extra: { place: :ctrl, type: :opt, args: [:third] }
				).message.should.equal(
					"Path '#{path}' has no optional arguments [:third]"
				)
			end

			it 'should be correct for extra path required arguments' do
				@init.call(
					path: '/foo/:first/:second/:third',
					extra: { place: :path, type: :req, args: [:third] }
				).message.should.equal(
					"Action 'ErrorsController#foo' has no required arguments [:third]"
				)
			end

			it 'should be correct for extra path optional arguments' do
				@init.call(
					path: '/foo/:first/:second/:?third/:?fourth/:?fifth',
					extra: { place: :path, type: :opt, args: [:fifth] }
				).message.should.equal(
					"Action 'ErrorsController#foo' has no optional arguments [:fifth]"
				)
			end
		end
	end
end
