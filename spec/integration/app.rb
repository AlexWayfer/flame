# frozen_string_literal: true

require_relative File.join('..', 'spec_helper')

require 'rack/test'

## Exampe of application
class IntegrationApp < Flame::Application
end

def app
	IntegrationApp.new
end
