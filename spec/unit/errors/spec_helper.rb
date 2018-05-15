# frozen_string_literal: true

require_relative '../../spec_helper'

## Test controller for Errors
class ErrorsController < Flame::Controller
	def foo(first, second, third = nil, fourth = nil); end
end
