# frozen_string_literal: true

describe 'Flame::Errors' do
	describe Flame::Errors::ControllerNotFoundError do
		let(:controller_name) { :foo }
		let(:namespace) { Flame::Errors }

		subject(:error) do
			described_class.new(controller_name, namespace)
		end

		let(:correct_message) do
			"Controller 'foo' not found for 'Flame::Errors'"
		end

		it_behaves_like 'error with correct output'
	end
end
