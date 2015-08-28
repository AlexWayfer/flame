## Test app for Framework
class MyApp < Atom::Nucleus
	puts '-- Init MyApp'

	get '/' do
		'index'
	end

	get '/users' do
		'Index of users' \
		'<form action="/users" method="POST">' \
			'<input type="submit" value="Create" />' \
		'</form>'
	end

	post '/users' do
		'Create new user'
	end

	get '/users/:id' do |id|
		"Show user by id = #{params[:id]}" \
		"<form action=\"/users/#{id}\" method=\"POST\">" \
			'<input type="hidden" name="_method" value="PUT" />' \
			'<input type="submit" value="Update" />' \
		'</form>' \
		"<form action=\"/users/#{id}\" method=\"POST\">" \
			'<input type="hidden" name="_method" value="DELETE" />' \
			'<input type="submit" value="Delete" />' \
		'</form>'
	end

	put '/users/:id' do
		"Update user by id = #{params[:id]}"
	end

	delete '/users/:id' do |id|
		"Delete user by id = #{id}"
	end

	get '/hello/:name' do |name|
		"Hello, #{name}"
	end

	get '/goodbye' do
		status 500
		'Goodbye Cruel World!'
	end
end
