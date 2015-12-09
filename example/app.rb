## Test app for Framework
class App < Flame::Application
	mount HomeController

	mount UsersController, '/users' do
		# get '/', :index
		# post '/', :create
		# get '/:id', :show
		# put '/:id', :update
		# delete '/:id', :delete
		# before [:index, :show], :check_access
		before :*, :check_param!
		defaults
	end
end
