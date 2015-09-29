## Demo REST controller
class UsersController < Flame::Controller
	def index
		view :index
	end

	def create
		render :create
	end

	def show(id)
		view :show, id: id
	end

	def update(id)
		render :update, id: id
	end

	def delete(id)
		render :delete, id: id
	end

	def hello(name = 'world')
		"Hello, #{name}"
	end
end
