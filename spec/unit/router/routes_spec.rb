# frozen_string_literal: true

describe Flame::Router::Routes do
	subject(:routes) { described_class.new(path) }

	let(:path) { '/foo/bar/baz' }

	describe '#initialize' do
		it { is_expected.to be_kind_of Hash }

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

		context 'with String which is not argument ' do
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

		context 'when path without arguments' do
			context 'with Path Part argument' do
				let(:args) { Flame::Path.new('/foo/bar').parts }

				it { is_expected.to eq('baz' => {}) }
			end

			context 'with String argument' do
				let(:args) { %w[foo bar] }

				it { is_expected.to eq('baz' => {}) }
			end
		end

		context 'when path with arguments' do
			let(:path) { '/:first/:second' }

			context 'with Path Part argument' do
				let(:args) { Flame::Path.new('/foo').parts }

				it { is_expected.to eq(':second' => {}) }
			end

			context 'with String argument' do
				let(:args) { 'foo' }

				it { is_expected.to eq(':second' => {}) }
			end
		end

		context 'when path with optional argument at beginning' do
			let(:path) { '/:?first/second/third' }

			context 'with Path Part argument' do
				let(:args) { Flame::Path.new('/second').parts }

				it { is_expected.to eq('third' => {}) }
			end

			context 'with String argument' do
				let(:args) { 'second' }

				it { is_expected.to eq('third' => {}) }
			end
		end

		context 'with root path' do
			let(:args) { '/' }

			it { is_expected.to eq('foo' => { 'bar' => { 'baz' => {} } }) }
		end

		context 'with nested routes from path' do
			let(:path) { '/foo/:?var/bar' }

			describe 'level one' do
				let(:args) { '/foo' }

				it { is_expected.to eq routes['foo'][':?var'] }
			end

			describe 'level two' do
				let(:args) { '/foo/some' }

				it { is_expected.to eq routes['foo'][':?var'] }
			end

			describe 'level three' do
				let(:args) { '/foo/some/bar' }

				it { is_expected.to eq routes['foo'][':?var']['bar'] }
			end
		end

		context 'with nonexistent path' do
			let(:args) { '/foo/baz' }

			it { is_expected.to be_nil }
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
			routes['foo']['bar'][:GET] = 42
			routes['foo']['bar']['bar'] = described_class.new
			routes['foo']['bar']['baz'][:DELETE] = 84
			routes['foo']['bar']['bar'][:POST] = 36
			routes['foo']['bar']['baz'][:GET] = 62
		end

		let(:expected_output) do
			<<~OUTPUT
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
