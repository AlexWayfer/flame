## Test app for Framework
class App < Flame::Application
	mount HomeController do
		defaults
	end

	mount UsersController, '/users' do
		# get '/', :index
		# post '/', :create
		# get '/:id', :show
		# put '/:id', :update
		# delete '/:id', :delete
		defaults
	end
end
