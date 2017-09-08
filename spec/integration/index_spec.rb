# frozen_string_literal: true

require_relative 'app'

## Example of index controller
class IndexController < Flame::Controller
	def index
		'This is index'
	end
end

## Mount example controller to app
class IntegrationApp
	mount :index, '/'
end

describe IndexController do
	it 'should return index' do
		get '/'
		last_response.should.be.ok
		last_response.body.should.equal 'This is index'
	end

	it 'should return default 404' do
		get '/404'
		last_response.should.be.not_found
		last_response.body.should.equal '<h1>Not Found</h1>'
	end
end
