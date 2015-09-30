## Test app for Framework
class MyApp < Flame::Application
	mount HomeController, '/home'

	mount UsersController, '/users' do
		# get '/', :index
		# post '/', :create
		# get '/:id', :show
		# put '/:id', :update
		# delete '/:id', :delete
		rest
		defaults
	end
end
