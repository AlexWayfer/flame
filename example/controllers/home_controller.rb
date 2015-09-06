## Demo casual controller
class HomeController < Flame::Controller
	def index
		'Welcome!'
	end

	def welcome(name)
		view 'home/welcome', name: name
	end
end
