# frozen_string_literal: true

describe Flame::Dispatcher::Request do
	before do
		@env_init = proc do |method: :PATCH|
			{
				Rack::REQUEST_METHOD => 'POST',
				Rack::PATH_INFO => '/hello/great/world',
				Rack::RACK_INPUT => StringIO.new("_method=#{method}"),
				Rack::RACK_REQUEST_FORM_HASH => { '_method' => method.to_s }
			}
		end
		@env = @env_init.call
		@request_init = proc do |env = @env|
			Flame::Dispatcher::Request.new(env)
		end
		@request = @request_init.call
	end

	it 'should be Rack::Request child' do
		@request.should.be.kind_of Rack::Request
	end

	describe '#path' do
		it 'should return Flame::Path by requested path' do
			@request.path.should.be.kind_of Flame::Path
			@request.path.should.equal '/hello/great/world'
		end
	end

	describe '#http_method' do
		it 'should have priority to return HTTP-method from parameter' do
			@request.http_method.should.equal :PATCH
		end

		it 'should return symbolized value' do
			@request.http_method.should.be.kind_of Symbol
		end

		it 'should return upcased value' do
			env = @env_init.call(method: :put)
			@request_init.call(env).http_method.should.equal :PUT
		end

		it 'should cache computed value' do
			custom_request_class = Class.new(Flame::Dispatcher::Request)
			custom_request_class.class_exec do
				attr_reader :params_execs

				def params
					@params_execs ||= 0
					@params_execs += 1
					super
				end
			end
			request = custom_request_class.new(@env)
			3.times { request.http_method }
			request.params_execs.should.equal 1
		end
	end
end
