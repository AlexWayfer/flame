# frozen_string_literal: true

## Controller for Controller tests
class ControllerController < Flame::Controller
	def foo(first, second = nil); end

	def bar
		view
	end

	def baz
		reroute AnotherControllerController, :baz
	end

	def object_hash
		hash
	end

	def respond_for_reroute
		'Hello from reroute'
	end

	def current_reroute
		reroute :respond_for_reroute
	end

	def hash_reroute
		reroute :object_hash
	end

	def index_reroute
		reroute AnotherControllerController
	end

	def execute_reroute
		reroute AnotherControllerController, :bar
	end

	def hooks_reroute
		reroute AnotherControllerController, :hooked
	end
end

## Another controller for Controller tests
class AnotherControllerController < Flame::Controller
	def index
		'Another index'
	end

	def hello(name = 'world')
		"Hello, #{name}!"
	end

	def bar
		'Another bar'
	end

	def baz
		'Another baz'
	end

	def hooked
		'Another hooked'
	end

	def back
		path_to_back
	end

	protected

	def execute(method)
		return body 'Another execute' if method == :bar
		super
		'after-hook' if method == :hooked
	end
end

module Nested
	class IndexController < Flame::Controller
		def index; end
	end

	class NestedController < Flame::Controller
		def back
			path_to_back
		end
	end
end

## Module for Controller tests
module SomeActions
	def included_action; end

	def another_included_action; end

	private

	def private_included_method; end
end

## Application for Controller tests
class ControllerApplication < Flame::Application
	mount ControllerController, '/'
	mount AnotherControllerController, '/another'

	mount Nested::IndexController do
		mount Nested::NestedController
	end
end

describe Flame::Controller do
	before do
		@env = {
			Rack::RACK_URL_SCHEME => 'http',
			Rack::SERVER_NAME => 'localhost',
			Rack::SERVER_PORT => 3000,
			Rack::RACK_INPUT => StringIO.new
		}
		@dispatcher = Flame::Dispatcher.new(ControllerApplication.new, @env)
		@controller = ControllerController.new(@dispatcher)
		@another_controller = AnotherControllerController.new(@dispatcher)
	end

	describe '.actions' do
		it 'should return all public not-inherited methods of Controller' do
			ControllerController.actions
				.should.equal ControllerController.public_instance_methods(false)
		end
	end

	describe '.default_path' do
		it 'should return downcased path based on controller name' do
			ControllerController.default_path
				.should.equal '/controller'
			AnotherControllerController.default_path
				.should.equal '/another_controller'
		end

		it 'should return downcased module name for index controller' do
			Nested::IndexController.default_path
				.should.equal '/nested'
		end
	end

	describe 'delegators' do
		it 'should delegate all needed methods' do
			needed_methods = %i[
				config request params halt session response status body
				default_body
			]
			(needed_methods - @controller.methods).should.be.empty
		end
	end

	describe '#initialize' do
		it 'should take dispatcher' do
			ControllerController.new(@dispatcher)
				.instance_variable_get(:@dispatcher)
				.should.equal @dispatcher
		end
	end

	describe '#path_to' do
		it 'should return path to another controller' do
			@controller.path_to(AnotherControllerController, :baz)
				.should.equal '/another/baz'
		end

		it 'should return path to index action of another controller by default' do
			@controller.path_to(AnotherControllerController)
				.should.equal '/another'
		end

		it 'should return path to self without controller argument' do
			@controller.path_to(:bar)
				.should.equal '/bar'
		end

		it 'should return path to self with arguments assigments' do
			@controller.path_to(:foo, first: 'Alex')
				.should.equal '/foo/Alex'
		end
	end

	describe '#url_to' do
		it 'should return URL by String path' do
			path = '/some/path?with=args'
			@controller.url_to(path)
				.should.equal "http://localhost:3000#{path}"
		end

		it 'should return URL by controller and action' do
			@controller.url_to(AnotherControllerController, :baz)
				.should.equal 'http://localhost:3000/another/baz'
		end

		it 'should return URL by action from self' do
			@controller.url_to(:foo, first: 'Alex')
				.should.equal 'http://localhost:3000/foo/Alex'
		end

		it 'should return URL by Flame::Path object' do
			path = Flame::Path.new '/some/path?with=args'
			@controller.url_to(path)
				.should.equal "http://localhost:3000#{path}"
		end

		it 'should return URL with mtime of static file in argmunet' do
			file = 'test.txt'
			mtime = File.mtime File.join(__dir__, 'public', file)
			@controller.url_to("/#{file}", version: true)
				.should.equal "http://localhost:3000/#{file}?v=#{mtime.to_i}"
		end
	end

	describe '#path_to_back' do
		should 'return referer URL if exist' do
			referer = 'http://example.com/'
			env = @env.merge(
				'HTTP_REFERER' => referer
			)
			dispatcher = Flame::Dispatcher.new(ControllerApplication.new, env)
			controller = AnotherControllerController.new(dispatcher)
			controller.back.should.equal referer
		end

		should 'not return referer with the same URL' do
			referer = 'http://localhost:3000/another/bar'
			env = @env.merge(
				Rack::PATH_INFO => '/another/bar',
				'HTTP_REFERER' => referer
			)
			dispatcher = Flame::Dispatcher.new(ControllerApplication.new, env)
			controller = AnotherControllerController.new(dispatcher)
			controller.back.should.not.equal referer
		end

		should 'return path to index action of controller without referer' do
			@another_controller.back.should.equal '/another'
		end

		should 'return root path without referer and index action' do
			env = @env.merge(
				Rack::PATH_INFO => '/nested/nested/back'
			)
			dispatcher = Flame::Dispatcher.new(ControllerApplication.new, env)
			controller = Nested::NestedController.new(dispatcher)
			controller.back.should.equal '/'
		end
	end

	describe '#redirect' do
		describe 'by String' do
			before do
				@url = 'http://example.com/'
			end

			it 'should write rediect to response' do
				@controller.redirect(@url)
				@controller.status.should.equal 302
				@controller.response.location.should.equal @url
			end

			it 'should receive status as last arument' do
				@controller.redirect(@url, 301)
				@controller.status.should.equal 301
				@controller.response.location.should.equal @url
			end

			it 'should not mutate args as array' do
				args = [@url, 302]
				@controller.redirect(*args)
				@controller.status.should.equal 302
				@controller.response.location.should.equal @url
				args.should.equal [@url, 302]
			end
		end

		describe 'by controller and action' do
			it 'should write rediect to response' do
				@controller.redirect(AnotherControllerController, :hello, name: 'Alex')
				@controller.status.should.equal 302
				@controller.response.location.should.equal '/another/hello/Alex'
			end

			it 'should receive status as last arument' do
				@controller.redirect(
					AnotherControllerController, :hello, { name: 'Alex' }, 301
				)
				@controller.status.should.equal 301
				@controller.response.location.should.equal '/another/hello/Alex'
			end

			it 'should not mutate args as array' do
				args = [AnotherControllerController, :hello, { name: 'Alex' }, 301]
				@controller.redirect(*args)
				@controller.status.should.equal 301
				@controller.response.location.should.equal '/another/hello/Alex'
				args.should.equal(
					[AnotherControllerController, :hello, { name: 'Alex' }, 301]
				)
			end
		end

		describe 'by URI object' do
			it 'should write redirect to response' do
				@controller.redirect URI::HTTP.build(host: 'example.com')
				@controller.status.should.equal 302
				@controller.response.location.should.equal 'http://example.com'
			end

			it 'should receive status as last arument' do
				@controller.redirect URI::HTTP.build(host: 'example.com'), 301
				@controller.status.should.equal 301
				@controller.response.location.should.equal 'http://example.com'
			end
		end

		it 'should return default status' do
			@controller.redirect('http://example.com/').should.equal 302
		end

		it 'should return specified status' do
			@controller.redirect('http://example.com/', 301).should.equal 301
		end
	end

	describe '#reroute' do
		it 'should call specified action of specified controller' do
			@controller.baz.should.equal 'Another baz'
		end

		it 'should call specified action of current controller' do
			@controller.current_reroute.should.equal 'Hello from reroute'
		end

		it 'should not recreate current controller' do
			@controller.hash_reroute.should.equal @controller.object_hash
		end

		it 'should call index action by default' do
			@controller.index_reroute.should.equal 'Another index'
		end

		it 'should call `execute` method of called controller' do
			@controller.execute_reroute.should.equal 'Another execute'
		end

		it 'should save result of action as body regardless of after-hooks' do
			@controller.hooks_reroute.should.equal 'Another hooked'
		end
	end

	describe '#attachment' do
		it 'should set default Content-Disposition header' do
			@controller.attachment
			@controller.response['Content-Disposition']
				.should.equal 'attachment'
		end

		it 'should set Content-Disposition header with filename' do
			@controller.attachment 'style.css'
			@controller.response['Content-Disposition']
				.should.equal 'attachment; filename="style.css"'
		end

		it 'should set Content-Type header by filename' do
			@controller.attachment 'style.css'
			@controller.response['Content-Type']
				.should.equal 'text/css'
		end
	end

	describe '#view' do
		it 'should render partial' do
			@controller.view(:_partial)
				.should.equal "<p>This is partial</p>\n"
		end

		it 'should render view with layout and instance variables' do
			@controller.instance_variable_set(:@name, 'user')
			@controller.view(:view)
				.should.equal <<~CONTENT
					<body>
						<h1>Hello, user!</h1>\n
					</body>
				CONTENT
		end

		it 'should receive options for Flame::Render' do
			@controller.view(:view, layout: false)
				.should.equal "<h1>Hello, world!</h1>\n"
		end

		it 'should raise error if template file not found' do
			-> { @controller.view(:nonexistent) }
				.should.raise(Flame::Errors::TemplateNotFoundError)
				.message.should.equal(
					"Template 'nonexistent' not found for 'ControllerController'"
				)
		end

		describe 'cache' do
			before do
				ControllerApplication.cached_tilts.clear
			end

			it 'should not work for development environment' do
				@controller.config[:environment] = 'development'
				@controller.view(:view)
				ControllerApplication.cached_tilts.should.be.empty
			end

			it 'should work for production environment' do
				@controller.config[:environment] = 'production'
				@controller.view(:view, layout: false)
				ControllerApplication.cached_tilts.size.should.equal 1
			end

			it 'should not work with false value of cache option' do
				@controller.config[:environment] = 'production'
				@controller.view(:view, cache: false)
				ControllerApplication.cached_tilts.should.be.empty
			end

			it 'should work with true value of cache option' do
				@controller.config[:environment] = 'development'
				@controller.view(:view, layout: false, cache: true)
				ControllerApplication.cached_tilts.size.should.equal 1
			end
		end

		it 'should take controller name as default path' do
			@controller.bar
				.should.equal <<~CONTENT
					<body>
						This is view for bar method of ControllerController\n
					</body>
				CONTENT
		end

		it 'should have `render` alias' do
			@controller.view(:view)
				.should.equal @controller.render(:view)
		end
	end

	describe 'ParentActions' do
		it 'should define actions from parent' do
			inherited_controller = Class.new(ControllerController)
			inherited_controller.extend Flame::Controller::ParentActions
			inherited_controller.actions.should.equal ControllerController.actions
		end

		it 'should define actions from parent without forbidden actions' do
			inherited_controller = Class.new(ControllerController)
			inherited_controller::FORBIDDEN_ACTIONS = %i[
				current_reroute hash_reroute index_reroute execute_reroute hooks_reroute
			].freeze
			inherited_controller.extend Flame::Controller::ParentActions
			inherited_controller.actions
				.should.equal %i[foo bar baz object_hash respond_for_reroute]
		end
	end

	describe '.with_actions' do
		it 'should define actions from parent' do
			inherited_controller = Class.new(ControllerController.with_actions)
			inherited_controller.actions.should.equal ControllerController.actions
		end

		describe 'include' do
			before do
				@controller_with_included_actions = Class.new(Flame::Controller) do
					include with_actions SomeActions

					def controller_action; end
				end
			end

			it 'should include actions from included module' do
				@controller_with_included_actions.actions
					.should.equal %i[
						included_action another_included_action controller_action
					]
			end
		end
	end
end
