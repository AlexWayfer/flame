# frozen_string_literal: true

require_relative File.join '..', '..', 'spec_helper'

## Test controller for Errors
class ErrorsController < Flame::Controller
	def foo(first, second, third = nil); end
end
