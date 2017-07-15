# frozen_string_literal: true

describe 'Flame::Errors' do
	describe Flame::Errors::TemplateNotFoundError do
		before do
			@ctrl_init = proc { ErrorsController.new(nil) }
			@init = proc do |controller: ErrorsController|
				Flame::Errors::TemplateNotFoundError.new(controller, :foo)
			end
			@error = @init.call
		end

		describe '#message' do
			it 'should be correct for controller class' do
				@error.message.should.equal(
					"Template 'foo' not found for 'ErrorsController'"
				)
			end

			it 'should be correct for controller object' do
				@init.call(controller: @ctrl_init.call)
					.message.should.equal(
						"Template 'foo' not found for 'ErrorsController'"
					)
			end
		end
	end
end
