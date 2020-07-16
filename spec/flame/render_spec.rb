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
	def render_init(*args)
		Flame::Render.new(controller, *args)
	end

	subject(:render) { render_init(*args) }

	let(:controller_class) { RenderTest::OneController }

	let(:controller) do
		controller_class.new(Flame::Dispatcher.new(RenderTest::Application, {}))
	end

	describe '#initialize' do
		context 'with only view name' do
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
			let(:args) { [:view, { foo: :bar }] }

			describe '@locals' do
				subject { super().instance_variable_get(:@locals) }

				it { is_expected.to eq foo: :bar }
			end
		end

		context 'with scope' do
			let(:scope) { Object.new }

			let(:args) { [:view, { scope: scope, foo: :bar }] }

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
			let(:args) { [:view, { layout: 'some', foo: :bar }] }

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
			let(:args) { [:view, { tilt: { outvar: 'baz' }, foo: :bar }] }

			describe '@locals' do
				subject { super().instance_variable_get(:@locals) }

				it { is_expected.to eq foo: :bar }
			end

			describe '@tilt_options' do
				subject { super().instance_variable_get(:@tilt_options) }

				it { is_expected.to eq outvar: 'baz' }
			end

			describe '#compile_file' do
				subject { super().send(:compile_file) }

				before do
					## warning: instance variable @cache not initialized
					render.instance_variable_set(:@cache, false)
				end

				## https://github.com/rtomayko/tilt/blob/752a852/lib/tilt/erb.rb#L20
				describe '@outvar' do
					subject { super().instance_variable_get(:@outvar) }

					it { is_expected.to eq 'baz' }
				end
			end
		end

		context 'with partial' do
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
		subject(:result) { render.render(&block) }

		let(:block) { nil }

		describe 'priority by controller name' do
			let(:controller_class) { RenderTest::AnotherOneController }

			let(:args) { :view }

			let(:expected_result) do
				<<~CONTENT
					<body>
						<h1>I am from controller name!</h1>\n
					</body>
				CONTENT
			end

			it { is_expected.to eq expected_result }
		end

		describe 'view with layout by default' do
			let(:args) { :view }

			let(:expected_result) do
				<<~CONTENT
					<body>
						<h1>Hello, world!</h1>\n
					</body>
				CONTENT
			end

			it { is_expected.to eq expected_result }
		end

		describe 'without layout by false option' do
			let(:args) { [:view, { layout: false }] }

			it { is_expected.to eq "<h1>Hello, world!</h1>\n" }
		end

		describe 'partial without layout by default' do
			let(:args) { :_partial }

			it { is_expected.to eq "<p>This is partial</p>\n" }
		end

		describe 'with nested layouts' do
			let(:args) { 'namespace/nested' }

			let(:expected_result) do
				<<~CONTENT
					<body>
						<div>
						<p>Double layout!</p>\n
					</div>\n
					</body>
				CONTENT
			end

			it { is_expected.to eq expected_result }
		end

		describe 'error if file not found' do
			let(:args) { :nonexistent }

			it do
				expect { result }.to raise_error(
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

			let(:expected_result) do
				<<~CONTENT
					Hello!
					There is nested:
					Deeply nested file.
				CONTENT
			end

			it { is_expected.to eq expected_result }
		end

		describe 'cache' do
			subject(:cached_tilts) { controller.cached_tilts }

			before do
				controller.cached_tilts.clear
			end

			context 'with false option' do
				let(:args) { [:view, { layout: false }] }

				it do
					2.times do
						render = render_init(*args)
						render.render(cache: false)

						expect(cached_tilts).to be_empty
					end
				end
			end

			context 'with true option' do
				let(:args) { [:view, { layout: false }] }

				describe 'cached_tilts.count' do
					subject(:cached_tilts_count) { cached_tilts.count }

					it do
						2.times do
							render = render_init(*args)
							render.render(cache: true)

							expect(cached_tilts_count).to eq 1
						end
					end
				end

				describe 'cached_tilts.keys' do
					subject(:cached_tilts_keys) { cached_tilts.keys }

					it do
						2.times do
							render = render_init(*args)
							render.render(cache: true)
						end

						expect(cached_tilts_keys).to all include 'view'
					end
				end
			end

			describe 'also layout' do
				let(:args) { :view }

				describe 'cached_tilts.count' do
					subject(:cached_tilts_count) { cached_tilts.count }

					it do
						render = render_init(*args)
						render.render(cache: true)

						expect(cached_tilts_count).to eq 2
					end
				end

				describe 'cached_tilts.keys' do
					subject(:cached_tilts_keys) { cached_tilts.keys }

					it do
						render = render_init(*args)
						render.render(cache: true)

						expect(cached_tilts_keys).to include include 'layout'
					end
				end
			end

			describe 'plain template without multiple layouts' do
				let(:args) { :plain }

				let(:expected_result) do
					<<~CONTENT
						<body>
							<span>text</span>\n
						</body>
					CONTENT
				end

				it do
					result = nil

					2.times do
						result = render.render(cache: true)
					end

					expect(result).to eq expected_result
				end
			end
		end
	end
end
