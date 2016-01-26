## Test app for Framework
class App < Flame::Application
	mount HomeController do
		error 500, :error!
		defaults
	end

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
