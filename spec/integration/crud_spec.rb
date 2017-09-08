# frozen_string_literal: true

require_relative 'app'

## Example of CRUD controller
class CRUDController < Flame::Controller
	def index
		'List of items'
	end

	def create
		'Create item'
	end

	def show(id)
		"Show item #{id}"
	end

	def update(id)
		"Edit item #{id}"
	end

	def delete(id)
		"Delete item #{id}"
	end
end

## Mount example controller to app
class IntegrationApp
	mount :CRUD
end

describe 'CRUD Controller' do
	it 'should return list of items' do
		get '/crud'
		last_response.should.be.ok
		last_response.body.should.equal 'List of items'
	end

	it 'should create item' do
		post '/crud'
		last_response.should.be.ok
		last_response.body.should.equal 'Create item'
	end

	it 'should show item' do
		get '/crud/2'
		last_response.should.be.ok
		last_response.body.should.equal 'Show item 2'
	end

	it 'should update item' do
		put '/crud/4'
		last_response.should.be.ok
		last_response.body.should.equal 'Edit item 4'
	end

	it 'should delete item' do
		delete '/crud/8'
		last_response.should.be.ok
		last_response.body.should.equal 'Delete item 8'
	end
end
