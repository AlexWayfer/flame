# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
	add_filter '/spec/'
end
SimpleCov.start

if ENV['CODECOV']
	require 'codecov'
	SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

require_relative File.join('..', 'lib', 'flame')

require 'bacon'
require 'pry-byebug'

def match_words(*words)
	regexp = words.map! { |word| "(?=.*#{Regexp.escape(word)})" }.join
	->(obj) { obj.match(/#{regexp}/m) }
end
