## Test app for Framework
class MyApp < Flame::Application
	mount HomeController, '/home' do
		get '/', :index
		get '/welcome/:last_name/:first_name', :welcome
	end

	mount UsersController, '/users' do
		get '/', :index
		post '/', :create
		get '/:id', :show
		put '/:id', :update
		delete '/:id', :delete
	end
end
