# frozen_string_literal: true

describe Flame::Router::Routes do
	def initialize_routes(path = nil, endpoints = nil)
		result = described_class.new(path)
		result.dig(*Flame::Path.new(path).parts).merge! endpoints if endpoints
		result
	end

	subject(:routes) { initialize_routes path, endpoints }

	let(:path) { '/foo/bar/baz' }
	let(:endpoints) { nil }

	describe '#initialize' do
		it { is_expected.to be_a Hash }

		context 'with path as Flame::Path' do
			let(:path) { Flame::Path.new('/foo/bar/baz') }

			it { is_expected.to eq('foo' => { 'bar' => { 'baz' => {} } }) }
		end

		context 'with path as String' do
			let(:path) { '/foo/bar/baz' }

			it { is_expected.to eq('foo' => { 'bar' => { 'baz' => {} } }) }
		end

		describe 'nested Hashes' do
			def deep_check(values)
				values.all? do |value|
					value.is_a?(Flame::Router::Routes) &&
						(deep_check(value.values) || value.values.empty?)
				end
			end

			subject { deep_check(routes.values) }

			it { is_expected.to be true }
		end
	end

	describe '#[]' do
		context 'with Path Part which is not argument' do
			subject { routes[Flame::Path::Part.new('foo')] }

			it { is_expected.to eq('bar' => { 'baz' => {} }) }
		end

		context 'with String which is not argument' do
			subject { routes['foo'] }

			it { is_expected.to eq('bar' => { 'baz' => {} }) }
		end

		context 'with HTTP-methods as Symbol keys' do
			subject { routes['foo']['bar'][:GET] }

			let(:path) { '/foo/bar' }

			before do
				routes['foo']['bar'][:GET] = 42
			end

			it { is_expected.to eq 42 }
		end
	end

	describe '#navigate' do
		subject { routes.navigate(*args) }

		let(:endpoints) do
			{ GET: Flame::Router::Route.new(:foo_controller, :baz_action) }
		end

		context 'when path without arguments' do
			let(:path) { '/foo/bar/baz' }

			context 'with Path Part argument' do
				let(:args) { Flame::Path.new('/foo/bar/baz').parts }

				it { is_expected.to eq endpoints }
			end

			context 'with String argument' do
				let(:args) { %w[foo bar baz] }

				it { is_expected.to eq endpoints }

				context 'with not complete path' do
					let(:args) { %w[foo bar] }

					it { is_expected.to be_nil }
				end
			end
		end

		context 'when path with arguments' do
			let(:path) { '/:first/:second' }

			context 'with Path Part argument' do
				let(:args) { Flame::Path.new('/foo/bar').parts }

				it { is_expected.to eq endpoints }
			end

			context 'with String arguments' do
				let(:args) { %w[foo bar] }

				it { is_expected.to eq endpoints }

				context 'with not complete path' do
					let(:args) { %w[foo] }

					it { is_expected.to be_nil }
				end
			end
		end

		context 'when path with optional argument at beginning' do
			let(:path) { '/:?first/second/third' }

			context 'with this optional argument' do
				context 'with Path Part argument' do
					let(:args) { Flame::Path.new('/foo/second/third').parts }

					it { is_expected.to eq endpoints }
				end

				context 'with String arguments' do
					let(:args) { %w[foo second third] }

					it { is_expected.to eq endpoints }

					context 'with not complete path' do
						let(:args) { %w[foo second] }

						it { is_expected.to be_nil }
					end
				end
			end

			context 'without this optional argument' do
				context 'with Path Part argument' do
					let(:args) { Flame::Path.new('/second/third').parts }

					it { is_expected.to eq endpoints }
				end

				context 'with String arguments' do
					let(:args) { %w[second third] }

					it { is_expected.to eq endpoints }

					context 'with not complete path' do
						let(:args) { %w[second] }

						it { is_expected.to be_nil }
					end
				end
			end
		end

		context 'with nonexistent path' do
			let(:args) { '/foo/baz' }

			it { is_expected.to be_nil }
		end

		context 'with concurent routes with optional argument at the start' do
			let(:path) { '/foo/bar' }
			let(:args) { path }

			let(:concurent_routes) { initialize_routes '/:?qux/baz' }

			before do
				routes.dig(*Flame::Path.new(path).parts).merge! concurent_routes
			end

			it { is_expected.to eq endpoints.merge(concurent_routes) }
		end
	end

	describe '#allow' do
		subject { super()['foo']['bar'].allow }

		context 'when multiple HTTP-methods are allowed' do
			let(:path) { '/foo/bar' }

			before do
				routes['foo']['bar'][:GET]  = 42
				routes['foo']['bar'][:POST] = 84
			end

			it { is_expected.to eq 'GET, POST, OPTIONS' }
		end

		context 'with nonexistent path' do
			it { is_expected.to be_nil }
		end
	end

	describe '#to_s' do
		subject { routes.to_s }

		before do
			routes[:GET] = 'Index'
			routes['foo']['bar'][:GET] = 42
			routes['foo']['bar']['bar'] = initialize_routes
			routes['foo']['bar']['baz'][:DELETE] = 84
			routes['foo']['bar']['bar'][:POST] = 36
			routes['foo']['bar']['baz'][:GET] = 62
		end

		let(:expected_output) do
			<<~OUTPUT
				\e[1m   GET /\e[22m
				       \e[3m\e[36mIndex\e[0m\e[23m
				\e[1m   GET /foo/bar\e[22m
				       \e[3m\e[36m42\e[0m\e[23m
				\e[1m  POST /foo/bar/bar\e[22m
				       \e[3m\e[36m36\e[0m\e[23m
				\e[1m   GET /foo/bar/baz\e[22m
				       \e[3m\e[36m62\e[0m\e[23m
				\e[1mDELETE /foo/bar/baz\e[22m
				       \e[3m\e[36m84\e[0m\e[23m
			OUTPUT
		end

		it { is_expected.to eq expected_output }

		describe 'output without color chars' do
			subject { super().gsub(/\e\[(\d+)m/, '') }

			let(:expected_output) do
				<<~OUTPUT
					   GET /
					       Index
					   GET /foo/bar
					       42
					  POST /foo/bar/bar
					       36
					   GET /foo/bar/baz
					       62
					DELETE /foo/bar/baz
					       84
				OUTPUT
			end

			it { is_expected.to eq expected_output }
		end
	end
end
