require_relative '../lib/flame'

Dir[File.join(__dir__, 'controllers', '*.rb')].each { |file| require file }

require_relative './my_app'

run MyApp.new
