# frozen_string_literal: true

class RenderController < Flame::Controller
end

class AnotherRenderController < Flame::Controller
end

class RenderApp < Flame::Application
	mount RenderController
	mount AnotherRenderController
end

describe Flame::Render do
	before do
		@controller_init = proc do |controller_class|
			controller_class.new(Flame::Dispatcher.new(RenderApp.new, {}))
		end
		@controller = @controller_init.call RenderController
		@init = proc { |*args| Flame::Render.new(@controller, *args) }
	end

	describe '#initialize' do
		it 'should have defaults' do
			render = @init.call(:view)
			render.instance_variable_get(:@scope).should.be.same_as @controller
			render.instance_variable_get(:@layout).should.be.equal 'layout.*'
			render.instance_variable_get(:@locals).should.be.equal({})
		end

		it 'should accept locals' do
			render = @init.call(:view, foo: :bar)
			render.instance_variable_get(:@locals).should.be.equal foo: :bar
		end

		it 'should take scope from locals' do
			render = @init.call(:view, scope: self, foo: :bar)
			render.instance_variable_get(:@locals).should.be.equal foo: :bar
			render.instance_variable_get(:@scope).should.be.same_as self
		end

		it 'should take layout from locals' do
			render = @init.call(:view, layout: 'some', foo: :bar)
			render.instance_variable_get(:@locals).should.be.equal foo: :bar
			render.instance_variable_get(:@layout).should.be.equal 'some'
		end

		it 'should not have layout for partials' do
			render = @init.call('_partial')
			render.instance_variable_get(:@layout).should.be.equal nil
		end

		it 'should find file' do
			render = @init.call(:view)
			expected_file = File.join(__dir__, 'views', 'view.html.erb')
			founded_file = File.realpath render.instance_variable_get(:@filename)
			founded_file.should.be.equal expected_file
		end
	end

	describe '#render' do
		it 'should find file priority by controller name' do
			controller = @controller_init.call AnotherRenderController
			render = Flame::Render.new(controller, :view)
			render.render
				.should.be.equal <<~CONTENT
					<body>
						<h1>I am from controller name!</h1>\n
					</body>
				CONTENT
		end

		it 'should render view with layout by default' do
			render = @init.call(:view)
			render.render
				.should.be.equal <<~CONTENT
					<body>
						<h1>Hello, world!</h1>\n
					</body>
				CONTENT
		end

		it 'should render view without layout by false option' do
			render = @init.call(:view, layout: false)
			render.render.should.be.equal(
				"<h1>Hello, world!</h1>\n"
			)
		end

		it 'should render partial without layout by default' do
			render = @init.call(:_partial)
			render.render.should.be.equal(
				"<p>This is partial</p>\n"
			)
		end

		it 'should render with nested layouts' do
			render = @init.call('namespace/nested')
			render.render
				.should.be.equal <<~CONTENT
					<body>
						<div>
						<p>Double layout!</p>\n
					</div>\n
					</body>
				CONTENT
		end

		describe 'cache' do
			before do
				@controller.cached_tilts.clear
			end

			it 'should not cache with false option' do
				first = @init.call(:view, layout: false)
				first.render(cache: false)
				@controller.cached_tilts.should.be.empty
				second = @init.call(:view, layout: false)
				@controller.cached_tilts.should.be.empty
				second.render(cache: false)
				@controller.cached_tilts.should.be.empty
			end

			it 'should cache with true option' do
				first = @init.call(:view, layout: false)
				first.render(cache: true)
				@controller.cached_tilts.size.should.equal 1
				second = @init.call(:view, layout: false)
				@controller.cached_tilts.size.should.equal 1
				second.render(cache: true)
				@controller.cached_tilts.size.should.equal 1
				@controller.cached_tilts.keys.first.should.include 'view'
			end

			it 'should cache with layout' do
				render = @init.call(:view)
				render.render(cache: true)
				@controller.cached_tilts.size.should.equal 2
				paths = @controller.cached_tilts.keys
				paths.any? { |path| path.include?('layout') }.should.equal true
			end

			it 'should render cached plain template multiple times' \
				' without multiple layouts' do
				render = @init.call(:plain)
				result = nil
				2.times { result = render.render(cache: true) }
				result.should.be.equal <<~CONTENT
					<body>
						<span>text</span>\n
					</body>
				CONTENT
			end
		end
	end
end
