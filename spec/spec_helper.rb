# frozen_string_literal: true

require 'pry-byebug'

require 'simplecov'

if ENV['CI']
	require 'simplecov-cobertura'
	SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
end

SimpleCov.start

RSpec.configure do |config|
	config.example_status_persistence_file_path = "#{__dir__}/examples.txt"
end

require_relative '../lib/flame'

Dir["#{__dir__}/**/spec_helper.rb"].sort.each do |spec_helper|
	next if spec_helper == __FILE__
	next if spec_helper.include?('require_dirs')

	require spec_helper
end

def transform_words_into_regexp(*words)
	words.map { |word| "(?=.*#{Regexp.escape(word)})" }.join
end

RSpec::Matchers.define :match_words do |*words|
	regexp = transform_words_into_regexp(*words.flatten)

	match do |actual|
		actual.match(/#{regexp}/m)
	end

	diffable
end
