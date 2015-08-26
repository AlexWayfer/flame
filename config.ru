require './lib/atom/atom'
require './my_app'

use Rack::Reloader

run MyApp.new