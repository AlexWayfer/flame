# frozen_string_literal: true
## Demo casual controller
class HomeController < Flame::Controller
	def index
		view :index
	end

	def welcome(first_name, last_name = nil)
		# p first_name, last_name
		# fail 'Lol'
		view 'home/welcome', first_name: first_name, last_name: last_name
	end

	protected

	def execute(method)
		super
	end

	def default_body
		view status
	end
end
