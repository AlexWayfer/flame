# frozen_string_literal: true

describe 'Flame::Errors' do
	describe Flame::Errors::TemplateNotFoundError do
		subject(:error) do
			Flame::Errors::TemplateNotFoundError.new(controller, :foo)
		end

		context 'controller class' do
			let(:controller) { ErrorsController }

			let(:correct_message) do
				"Template 'foo' not found for 'ErrorsController'"
			end

			it_behaves_like 'error with correct output'
		end

		context 'controller object' do
			let(:controller) { ErrorsController.new(nil) }

			let(:correct_message) do
				"Template 'foo' not found for 'ErrorsController'"
			end

			it_behaves_like 'error with correct output'
		end
	end
end
