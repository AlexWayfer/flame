# frozen_string_literal: true

require_relative '../lib/flame'

Dir[File.join(__dir__, 'controllers', '*.rb')].each { |file| require file }

require_relative './app'

run App.new
