# frozen_string_literal: true

## Test controller for Dispatcher
class DispatcherController < Flame::Controller
	def index; end

	def foo; end

	def hello(name)
		"Hello, #{name}!"
	end
end

## Test application for Dispatcher
class DispatcherApplication < Flame::Application
	mount DispatcherController, '/'
end

describe Flame::Dispatcher do
	before do
		@init = lambda do |path: '/hello/world', query: nil|
			@env = {
				Rack::REQUEST_METHOD => 'GET',
				Rack::PATH_INFO => path,
				Rack::RACK_INPUT => StringIO.new,
				Rack::RACK_ERRORS => StringIO.new,
				Rack::QUERY_STRING => query
			}
			Flame::Dispatcher.new(DispatcherApplication.new, @env)
		end
		@dispatcher = @init.call
	end

	describe 'attrs' do
		it 'should have request reader' do
			@dispatcher.request.should.be.instance_of Flame::Request
		end

		it 'should have response reader' do
			@dispatcher.response.should.be.instance_of Flame::Response
		end
	end

	describe '#initialize' do
		it 'should take @app variable' do
			@dispatcher.instance_variable_get(:@app)
				.should.be.instance_of DispatcherApplication
		end

		it 'should take @env variable' do
			@dispatcher.instance_variable_get(:@env)
				.should.equal @env
		end

		it 'should take @request variable from env' do
			@dispatcher.request.env.should.equal @env
		end

		it 'should initialize @response variable' do
			@dispatcher.response.should.be.instance_of Flame::Response
		end
	end

	describe '#run!' do
		it 'should return respond from existing route' do
			respond = @dispatcher.run!.last
			respond.status.should.equal 200
			respond.body.should.equal ['Hello, world!']
		end

		it 'should return content of existing static file' do
			respond = @init.call(path: 'test.txt').run!.last
			respond.status.should.equal 200
			respond.body.should.equal ["Test static\n"]
		end

		it 'should return content of existing static file in gem' do
			respond = @init.call(path: 'favicon.ico').run!.last
			respond.status.should.equal 200
			favicon_file = File.join __dir__, '..', '..', 'public', 'favicon.ico'
			respond.body.should.equal [File.read(favicon_file)]
		end

		it 'should return 404 if neither route nor static file was found' do
			respond = @init.call(path: 'bar').run!.last
			respond.status.should.equal 404
			respond.body.should.equal ['<h1>Not Found</h1>']
		end
	end

	describe '#status' do
		it 'should return 200 by default' do
			@dispatcher.status.should.equal 200
		end

		it 'should take status' do
			@dispatcher.status 101
			@dispatcher.status.should.equal 101
		end

		it 'should set status to response' do
			@dispatcher.status 101
			@dispatcher.response.status.should.equal 101
		end

		it 'should set X-Cascade header for 404 status' do
			@dispatcher.status 404
			@dispatcher.response['X-Cascade'].should.equal 'pass'
		end
	end

	describe '#body' do
		it 'should set @body variable' do
			@dispatcher.body 'Hello!'
			@dispatcher.instance_variable_get(:@body).should.equal 'Hello!'
		end

		it 'should get @body variable' do
			@dispatcher.body 'Hello!'
			@dispatcher.body.should.equal 'Hello!'
		end
	end

	describe '#params' do
		it 'should return params from request with Symbol keys' do
			@init.call(path: '/hello', query: 'name=world&when=now').params
				.should.equal Hash[name: 'world', when: 'now']
		end

		it 'should not be the same Hash as params from request' do
			dispatcher = @init.call(path: '/hello', query: 'name=world&when=now')
			dispatcher.params.should.not.be.same_as dispatcher.request.params
		end

		it 'should cache Hash of params' do
			dispatcher = @init.call(path: '/hello', query: 'name=world&when=now')
			dispatcher.params.should.be.same_as dispatcher.params
		end
	end

	describe '#session' do
		it 'should return Object from Request' do
			@dispatcher.session.should.be.same_as @dispatcher.request.session
		end
	end

	describe '#cookies' do
		it 'should return instance of Flame::Cookies' do
			@dispatcher.cookies.should.be.instance_of Flame::Dispatcher::Cookies
		end

		it 'should cache the object' do
			@dispatcher.cookies.should.be.same_as @dispatcher.cookies
		end
	end

	describe '#config' do
		it 'should return config from app' do
			@dispatcher.config
				.should.be.same_as @dispatcher.instance_variable_get(:@app).config
		end
	end

	describe '#path_to' do
		it 'should return path by controller and action' do
			@dispatcher.path_to(DispatcherController, :foo)
				.should.equal '/foo'
		end

		it 'should return path by controller with default index action' do
			@dispatcher.path_to(DispatcherController)
				.should.equal '/'
		end

		it 'should return path by controller and action with arguments' do
			@dispatcher.path_to(DispatcherController, :hello, name: 'world')
				.should.equal '/hello/world'
		end

		it 'should raise error if route not found' do
			-> { @dispatcher.path_to(DispatcherController, :bar) }
				.should.raise(Flame::Errors::RouteNotFoundError)
				.message.should match_words('DispatcherController', 'bar')
		end

		it 'should return path with (nested) params' do
			@dispatcher.path_to(
				DispatcherController,
				:foo,
				params: {
					name: 'world',
					nested: { some: 'here', another: %w[there maybe] }
				}
			)
				.should.equal '/foo?name=world' \
					'&nested[some]=here&nested[another][]=there&nested[another][]=maybe'
		end
	end

	describe '#halt' do
		it 'should just throw without changes if no arguments' do
			-> { @dispatcher.halt }.should.throw(:halt)
			@dispatcher.status.should.equal 200
			@dispatcher.body.should.equal @dispatcher.default_body
		end

		it 'should take new status and write default body' do
			-> { @dispatcher.halt 500 }.should.throw(:halt)
			@dispatcher.status.should.equal 500
			@dispatcher.body.should.equal @dispatcher.default_body
		end

		it 'should not write default body for status without entity body' do
			-> { @dispatcher.halt 101 }.should.throw(:halt)
			@dispatcher.status.should.equal 101
			@dispatcher.body.should.be.empty
		end

		it 'should take new body' do
			-> { @dispatcher.halt 404, 'Nobody here' }.should.throw(:halt)
			@dispatcher.status.should.equal 404
			@dispatcher.body.should.equal 'Nobody here'
		end

		it 'should take new headers' do
			-> { @dispatcher.halt 200, 'Cats!', 'Content-Type' => 'animal/cat' }
				.should.throw(:halt)
			@dispatcher.status.should.equal 200
			@dispatcher.body.should.equal 'Cats!'
			@dispatcher.response.headers['Content-Type'].should.equal 'animal/cat'
		end
	end

	describe '#dump_error' do
		before do
			@error = RuntimeError.new 'Just an example error'
			@error.set_backtrace(caller)
		end

		it 'should write full information to @env[Rack::RACK_ERRORS]' do
			@dispatcher.dump_error(@error)
			@dispatcher.instance_variable_get(:@env)[Rack::RACK_ERRORS].string
				.should match_words(
					Time.now.strftime('%Y-%m-%d %H:%M:%S'),
					@error.class.name, @error.message, __FILE__
				)
		end
	end

	describe '#default_body' do
		it 'should return default body as <h1> for any setted status' do
			@dispatcher.status 200
			@dispatcher.default_body.should.equal '<h1>OK</h1>'

			@dispatcher.status 404
			@dispatcher.default_body.should.equal '<h1>Not Found</h1>'

			@dispatcher.status 500
			@dispatcher.default_body.should.equal '<h1>Internal Server Error</h1>'
		end
	end
end
