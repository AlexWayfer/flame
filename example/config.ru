require_relative '../lib/atom/atom'
require_relative './my_app'

use Rack::Reloader

run MyApp.new
