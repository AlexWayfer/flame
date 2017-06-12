# frozen_string_literal: true

describe Flame::Dispatcher::Cookies do
	before do
		@env = {
			'HTTP_COOKIE' => 'foo=bar; baz=bat'
		}
		@request = Flame::Dispatcher::Request.new(@env)
		@response = Flame::Dispatcher::Response.new
		@init = proc do |request_cookies, response|
			Flame::Dispatcher::Cookies.new(request_cookies, response)
		end
		@cookies = @init.call(@request.cookies, @response)
	end

	describe '#initialize' do
		it 'should recieve cookies from Request object and Response object' do
			-> { @init.call(@request.cookies, @response) }
				.should.not.raise ArgumentError
		end
	end

	describe '#[]' do
		it 'should return cookie by String key' do
			@cookies['foo'].should.equal 'bar'
		end

		it 'should return cookie by Symbol key' do
			@cookies[:baz].should.equal 'bat'
		end
	end

	describe '#[]=' do
		it 'should set new cookie for response' do
			@cookies[:abc] = 'xyz'
			@response[Rack::SET_COOKIE].should.include 'abc=xyz;'
		end

		it 'should delete cookie for response by nil value' do
			@cookies[:abc] = 'xyz'
			@response[Rack::SET_COOKIE].should.include 'abc=xyz;'
			@cookies[:abc] = nil
			@response[Rack::SET_COOKIE].should.include 'abc=;'
		end
	end
end
