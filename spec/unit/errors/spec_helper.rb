# frozen_string_literal: true

require_relative '../../spec_helper'

## Test controller for Errors
class ErrorsController < Flame::Controller
	def foo(first, second, third = nil, fourth = nil); end
end

shared_examples 'error with correct output' do
	describe '#message' do
		subject { super().message }

		it { is_expected.to eq correct_message }
	end

	describe '#inspect' do
		subject { super().inspect }

		it { is_expected.to eq "#<#{error.class}: #{correct_message}>" }
	end
end
