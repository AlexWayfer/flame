# frozen_string_literal: true

describe 'Flame::Errors' do
	describe Flame::Errors::TemplateNotFoundError do
		before do
			@init = lambda do |controller|
				Flame::Errors::TemplateNotFoundError.new(controller, :foo)
			end
		end

		describe 'controller class' do
			before do
				@error = @init.call(ErrorsController)

				@correct_message = "Template 'foo' not found for 'ErrorsController'"
			end

			behaves_like 'error with correct output'
		end

		describe 'controller object' do
			before do
				@error = @init.call(ErrorsController.new(nil))

				@correct_message = "Template 'foo' not found for 'ErrorsController'"
			end

			behaves_like 'error with correct output'
		end
	end
end
