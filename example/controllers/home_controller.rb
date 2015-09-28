## Demo casual controller
class HomeController < Flame::Controller
	def index
		'Welcome!'
	end

	def welcome(first_name, last_name)
		view 'home/welcome', first_name: first_name, last_name: last_name
	end
end
