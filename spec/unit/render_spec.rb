# frozen_string_literal: true

module RenderTest
	class OneController < Flame::Controller
	end

	class AnotherOneController < Flame::Controller
	end

	class Application < Flame::Application
		mount OneController
		mount AnotherOneController
	end
end

describe Flame::Render do
	let(:controller_class) { RenderTest::OneController }

	let(:controller) do
		controller_class.new(Flame::Dispatcher.new(RenderTest::Application, {}))
	end

	def render_init(*args)
		Flame::Render.new(controller, *args)
	end

	subject(:render) { render_init(*args) }

	describe '#initialize' do
		context 'only view name' do
			let(:args) { :view }

			describe '@scope' do
				subject { super().instance_variable_get(:@scope) }

				it { is_expected.to be controller }
			end

			describe '@layout' do
				subject { super().instance_variable_get(:@layout) }

				it { is_expected.to eq 'layout.*' }
			end

			describe '@locals' do
				subject { super().instance_variable_get(:@locals) }

				it { is_expected.to eq({}) }
			end
		end

		context 'with locals' do
			let(:args) { [:view, foo: :bar] }

			describe '@locals' do
				subject { super().instance_variable_get(:@locals) }

				it { is_expected.to eq foo: :bar }
			end
		end

		context 'with scope' do
			let(:scope) { Object.new }

			let(:args) { [:view, scope: scope, foo: :bar] }

			describe '@locals' do
				subject { super().instance_variable_get(:@locals) }

				it { is_expected.to eq foo: :bar }
			end

			describe '@scope' do
				subject { super().instance_variable_get(:@scope) }

				it { is_expected.to be scope }
			end
		end

		context 'with layout' do
			let(:args) { [:view, layout: 'some', foo: :bar] }

			describe '@locals' do
				subject { super().instance_variable_get(:@locals) }

				it { is_expected.to eq foo: :bar }
			end

			describe '@layout' do
				subject { super().instance_variable_get(:@layout) }

				it { is_expected.to be 'some' }
			end
		end

		context 'with tilt options' do
			let(:args) { [:view, tilt: { outvar: 'baz' }, foo: :bar] }

			describe '@locals' do
				subject { super().instance_variable_get(:@locals) }

				it { is_expected.to eq foo: :bar }
			end

			describe '@tilt_options' do
				subject { super().instance_variable_get(:@tilt_options) }

				it { is_expected.to eq outvar: 'baz' }
			end

			describe '#compile_file' do
				before do
					## warning: instance variable @cache not initialized
					render.instance_variable_set(:@cache, false)
				end

				subject { super().send(:compile_file) }

				## https://github.com/rtomayko/tilt/blob/752a852/lib/tilt/erb.rb#L20
				describe '@outvar' do
					subject { super().instance_variable_get(:@outvar) }

					it { is_expected.to eq 'baz' }
				end
			end
		end

		context 'partial' do
			let(:args) { '_partial' }

			describe '@layout' do
				subject { super().instance_variable_get(:@layout) }

				it { is_expected.to be_nil }
			end
		end

		describe 'file search' do
			let(:args) { :view }

			describe '@filename' do
				subject { File.realpath super().instance_variable_get(:@filename) }

				it { is_expected.to eq File.join(__dir__, 'views/view.html.erb') }
			end
		end
	end

	describe '#render' do
		subject { super().render(&block) }

		let(:block) { nil }

		describe 'priority by controller name' do
			let(:controller_class) { RenderTest::AnotherOneController }

			let(:args) { :view }

			it do
				is_expected.to eq <<~CONTENT
					<body>
						<h1>I am from controller name!</h1>\n
					</body>
				CONTENT
			end
		end

		describe 'view with layout by default' do
			let(:args) { :view }

			it do
				is_expected.to eq <<~CONTENT
					<body>
						<h1>Hello, world!</h1>\n
					</body>
				CONTENT
			end
		end

		describe 'without layout by false option' do
			let(:args) { [:view, layout: false] }

			it { is_expected.to eq "<h1>Hello, world!</h1>\n" }
		end

		describe 'partial without layout by default' do
			let(:args) { :_partial }

			it { is_expected.to eq "<p>This is partial</p>\n" }
		end

		describe 'with nested layouts' do
			let(:args) { 'namespace/nested' }

			it do
				is_expected.to eq <<~CONTENT
					<body>
						<div>
						<p>Double layout!</p>\n
					</div>\n
					</body>
				CONTENT
			end
		end

		describe 'error if file not found' do
			let(:args) { :nonexistent }

			it do
				expect { subject }.to raise_error(
					Flame::Errors::TemplateNotFoundError,
					"Template 'nonexistent' not found for 'RenderTest::OneController'"
				)
			end
		end

		describe 'block for template' do
			let(:args) { :_partial_with_block }

			let(:block) { -> { 'world' } }

			it { is_expected.to eq "<h1>Hello, world!</h1>\n" }
		end

		describe 'by relative name' do
			let(:args) { 'namespace/_will_render_nested' }

			it do
				is_expected.to eq <<~CONTENT
					Hello!
					There is nested:
					Deeply nested file.
				CONTENT
			end
		end

		describe 'cache' do
			before do
				controller.cached_tilts.clear
			end

			subject { controller.cached_tilts }

			context 'with false option' do
				let(:args) { [:view, layout: false] }

				it do
					2.times do
						render = render_init(*args)
						render.render(cache: false)

						is_expected.to be_empty
					end
				end
			end

			context 'with true option' do
				let(:args) { [:view, layout: false] }

				describe 'cached_tilts.count' do
					subject { super().count }

					it do
						2.times do
							render = render_init(*args)
							render.render(cache: true)

							is_expected.to eq 1
						end
					end
				end

				describe 'cached_tilts.keys' do
					subject { super().keys }

					it do
						2.times do
							render = render_init(*args)
							render.render(cache: true)
						end

						is_expected.to all include 'view'
					end
				end
			end

			describe 'also layout' do
				let(:args) { :view }

				describe 'cached_tilts.count' do
					subject { super().count }

					it do
						render = render_init(*args)
						render.render(cache: true)

						is_expected.to eq 2
					end
				end

				describe 'cached_tilts.keys' do
					subject { super().keys }

					it do
						render = render_init(*args)
						render.render(cache: true)

						is_expected.to include include 'layout'
					end
				end
			end

			describe 'plain template without multiple layouts' do
				let(:args) { :plain }

				it do
					result = nil

					2.times do
						result = render.render(cache: true)
					end

					expect(result).to eq <<~CONTENT
						<body>
							<span>text</span>\n
						</body>
					CONTENT
				end
			end
		end
	end
end
