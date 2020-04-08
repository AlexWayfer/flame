# frozen_string_literal: true

describe Flame::Errors::ControllerNotFoundError do
	subject(:error) { described_class.new(controller_name, namespace) }

	let(:controller_name) { :foo }
	let(:namespace) { Flame::Errors }

	let(:correct_message) do
		"Controller 'foo' not found for 'Flame::Errors'"
	end

	it_behaves_like 'error with correct output'
end
