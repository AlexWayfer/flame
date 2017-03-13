# frozen_string_literal: true
class RenderApp < Flame::Application
end

class RenderCtrl < Flame::Controller
end

class AnotherCtrl < Flame::Controller
end

describe Flame::Render do
	before do
		@ctrl = RenderCtrl.new(Flame::Dispatcher.new(RenderApp, {}))
	end

	describe '#initialize' do
		it 'should have defaults' do
			render = Flame::Render.new(@ctrl, :view)
			render.instance_variable_get(:@scope).should.be.same_as @ctrl
			render.instance_variable_get(:@layout).should.be.equal 'layout.*'
			render.instance_variable_get(:@locals).should.be.equal({})
		end

		it 'should accept locals' do
			render = Flame::Render.new(@ctrl, :view, foo: :bar)
			render.instance_variable_get(:@locals).should.be.equal foo: :bar
		end

		it 'should take scope from locals' do
			render = Flame::Render.new(@ctrl, :view, scope: self, foo: :bar)
			render.instance_variable_get(:@locals).should.be.equal foo: :bar
			render.instance_variable_get(:@scope).should.be.same_as self
		end

		it 'should take layout from locals' do
			render = Flame::Render.new(@ctrl, :view, layout: 'some', foo: :bar)
			render.instance_variable_get(:@locals).should.be.equal foo: :bar
			render.instance_variable_get(:@layout).should.be.equal 'some'
		end

		it 'should not have layout for partials' do
			render = Flame::Render.new(@ctrl, '_partial')
			render.instance_variable_get(:@layout).should.be.equal nil
		end

		it 'should find file' do
			render = Flame::Render.new(@ctrl, :view)
			expected_file = File.join(__dir__, 'views', 'view.html.erb')
			founded_file = File.realpath render.instance_variable_get(:@filename)
			founded_file.should.be.equal expected_file
		end
	end

	describe '#render' do
		it 'should find file priority by controller name' do
			ctrl = AnotherCtrl.new(Flame::Dispatcher.new(RenderApp, {}))
			render = Flame::Render.new(ctrl, :view)
			render.render.should.be.equal(
				"<body>\n\t<h1>I am from controller name!</h1>\n\n</body>\n"
			)
		end

		it 'should render view with layout by default' do
			render = Flame::Render.new(@ctrl, :view)
			render.render.should.be.equal(
				"<body>\n\t<h1>Hello, world!</h1>\n\n</body>\n"
			)
		end

		it 'should render view without layout by false option' do
			render = Flame::Render.new(@ctrl, :view, layout: false)
			render.render.should.be.equal(
				"<h1>Hello, world!</h1>\n"
			)
		end

		it 'should render partial without layout by default' do
			render = Flame::Render.new(@ctrl, :_partial)
			render.render.should.be.equal(
				"<p>This is partial</p>\n"
			)
		end

		describe 'cache' do
			it 'should not cache with false option' do
				my_render = Class.new(Flame::Render)
				first = my_render.new(@ctrl, :view, layout: false)
				first.render(cache: false)
				first.class.tilts.should.be.empty
				second = my_render.new(@ctrl, :view, layout: false)
				second.class.tilts.should.be.empty
				second.render(cache: false)
				second.class.tilts.should.be.empty
			end

			it 'should cache with true option' do
				my_render = Class.new(Flame::Render)
				first = my_render.new(@ctrl, :view, layout: false)
				first.render(cache: true)
				first.class.tilts.size.should.equal 1
				second = my_render.new(@ctrl, :view, layout: false)
				second.class.tilts.size.should.equal 1
				second.render(cache: true)
				second.class.tilts.size.should.equal 1
				second.class.tilts.keys.first.should.include 'view'
			end

			it 'should cache with layout' do
				my_render = Class.new(Flame::Render)
				render = my_render.new(@ctrl, :view)
				render.render(cache: true)
				render.class.tilts.size.should.equal 2
				paths = render.class.tilts.keys
				paths.any? { |path| path.include?('layout') }.should.equal true
			end

			it 'should render with nested layouts' do
				render = Flame::Render.new(@ctrl, 'namespace/nested')
				render.render.should.be.equal(
					"<body>\n\t<div>\n\t<p>Double layout!</p>\n\n</div>\n\n</body>\n"
				)
			end

			it 'should render cached plain template multiple times' \
				' without multiple layouts' do
				render = Flame::Render.new(@ctrl, :plain)
				result = nil
				2.times { result = render.render(cache: true) }
				result.should.be.equal(
					"<body>\n\t<span>text</span>\n\n</body>\n"
				)
			end
		end
	end
end
