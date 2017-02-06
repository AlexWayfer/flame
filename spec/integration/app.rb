require_relative File.join('..', 'spec_helper')

require 'rack/test'
include Rack::Test::Methods

## Exampe of application
class MyApp < Flame::Application
end

def app
	MyApp.new
end
