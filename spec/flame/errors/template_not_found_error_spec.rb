# frozen_string_literal: true

require_relative '../../../lib/flame/errors/template_not_found_error'

describe Flame::Errors::TemplateNotFoundError do
	subject(:error) { described_class.new(controller, :foo) }

	context 'with controller class' do
		let(:controller) { ErrorsController }

		let(:correct_message) do
			"Template 'foo' not found for 'ErrorsController'"
		end

		it_behaves_like 'error with correct output'
	end

	context 'with controller object' do
		let(:controller) { ErrorsController.new(nil) }

		let(:correct_message) do
			"Template 'foo' not found for 'ErrorsController'"
		end

		it_behaves_like 'error with correct output'
	end
end
