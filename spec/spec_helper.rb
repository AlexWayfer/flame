require 'simplecov'
SimpleCov.start do
	add_filter '/spec/'
end
SimpleCov.start

require_relative File.join('..', 'lib', 'flame')

require 'bacon'
require 'bacon/colored_output'
