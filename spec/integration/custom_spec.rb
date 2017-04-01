# frozen_string_literal: true

require_relative 'app'

## Example of custom controller
class CustomController < Flame::Controller
	def foo
		'This is foo'
	end

	def hello(name = 'world')
		"Hello, #{name}!"
	end

	# def page(*path_parts)
	# 	path_parts.join '/'
	# end

	def error
		raise StandardError
	end

	private

	def execute(method)
		super
	rescue => exception
		@rescued = true
		body default_body
		raise exception
	end

	def default_body
		result = "Some page about #{status} code"
		result += "; rescued is #{@rescued}" if status == 500
		result
	end
end

## Mount example controller to app
class IntegrationApp
	mount CustomController
end

describe CustomController do
	it 'should return foo' do
		get '/custom/foo'
		last_response.should.be.ok
		last_response.body.should.equal 'This is foo'
	end

	it 'should return hello with world' do
		get '/custom/hello'
		last_response.should.be.ok
		last_response.body.should.equal 'Hello, world!'
	end

	it 'should return hello with name' do
		get '/custom/hello/Alex'
		last_response.should.be.ok
		last_response.body.should.equal 'Hello, Alex!'
	end

	it 'should return custom 404' do
		get '/custom/foo/404'
		last_response.should.be.not_found
		last_response.body.should.equal 'Some page about 404 code'
	end

	it 'should return custom 500' do
		get '/custom/error'
		last_response.should.be.server_error
		last_response.body.should.equal 'Some page about 500 code; rescued is true'
	end
end
