# frozen_string_literal: true

require_relative '../../spec_helper'

## Test controller for Errors
class ErrorsController < Flame::Controller
	def foo(first, second, third = nil, fourth = nil); end
end

shared 'error with correct output' do
	describe '#message' do
		it 'should be correct' do
			@error.message.should.equal @correct_message
		end
	end

	describe '#inspect' do
		it 'should be correct' do
			@error.inspect.should.equal "#<#{@error.class}: #{@correct_message}>"
		end
	end
end
