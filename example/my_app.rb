## Test app for Framework
class MyApp < Flame::Application
	# get '/' do
	# 	view :index
	# end
	#
	# get '/users' do
	# 	view 'users/index'
	# end
	#
	# post '/users' do
	# 	view 'users/create'
	# end
	#
	# get '/users/:id' do |id|
	# 	view 'users/show', locals: { id: id }
	# end
	#
	# put '/users/:id' do
	# 	view 'users/update'
	# end
	#
	# delete '/users/:id' do
	# 	view 'users/delete'
	# end
	#
	# get '/hello/:name' do |name|
	# 	view :hello, name: name
	# end
	#
	# get '/goodbye' do
	# 	status 500
	# 	'Goodbye Cruel World!'
	# end

	mount HomeController, '/home' do
		get '/', :index
		get '/welcome/:name', :welcome
	end
	mount UsersController, '/users' do
		get '/', :index
		post '/', :create
		get '/:id', :show
		put '/:id', :update
		delete '/:id', :delete
	end
end
