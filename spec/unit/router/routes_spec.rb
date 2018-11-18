# frozen_string_literal: true

describe Flame::Router::Routes do
	let(:path) { '/foo/bar/baz' }

	subject(:routes) { Flame::Router::Routes.new(path) }

	describe '#initialize' do
		it { is_expected.to be_kind_of Hash }

		context 'path as Flame::Path' do
			let(:path) { Flame::Path.new('/foo/bar/baz') }

			it { is_expected.to eq('foo' => { 'bar' => { 'baz' => {} } }) }
		end

		context 'path as String' do
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
		context 'Path Part for key which is not argument' do
			subject { super()[Flame::Path::Part.new('foo')] }

			it { is_expected.to eq('bar' => { 'baz' => {} }) }
		end

		context 'String for key which is not argument ' do
			subject { super()['foo'] }

			it { is_expected.to eq('bar' => { 'baz' => {} }) }
		end

		context 'HTTP-methods as Symbol keys' do
			let(:path) { '/foo/bar' }

			subject { super()['foo']['bar'][:GET] }

			before do
				routes['foo']['bar'][:GET] = 42
			end

			it { is_expected.to eq 42 }
		end
	end

	describe '#navigate' do
		subject { super().navigate(*args) }

		context 'path without arguments' do
			context 'Path Part argument' do
				let(:args) { Flame::Path.new('/foo/bar').parts }

				it { is_expected.to eq('baz' => {}) }
			end

			context 'String argument' do
				let(:args) { %w[foo bar] }

				it { is_expected.to eq('baz' => {}) }
			end
		end

		context 'path with arguments' do
			let(:path) { '/:first/:second' }

			context 'Path Part argument' do
				let(:args) { Flame::Path.new('/foo').parts }

				it { is_expected.to eq(':second' => {}) }
			end

			context 'String argument' do
				let(:args) { 'foo' }

				it { is_expected.to eq(':second' => {}) }
			end
		end

		context 'path with optional argument at beginning' do
			let(:path) { '/:?first/second/third' }

			context 'Path Part argument' do
				let(:args) { Flame::Path.new('/second').parts }

				it { is_expected.to eq('third' => {}) }
			end

			context 'String argument' do
				let(:args) { 'second' }

				it { is_expected.to eq('third' => {}) }
			end
		end

		context 'root path' do
			let(:args) { '/' }

			it { is_expected.to eq('foo' => { 'bar' => { 'baz' => {} } }) }
		end

		context 'nested routes from path' do
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

		context 'nonexistent path' do
			let(:args) { '/foo/baz' }

			it { is_expected.to be_nil }
		end
	end

	describe '#allow' do
		subject { super()['foo']['bar'].allow }

		context 'multiple allow HTTP-methods' do
			let(:path) { '/foo/bar' }

			before do
				routes['foo']['bar'][:GET]  = 42
				routes['foo']['bar'][:POST] = 84
			end

			it { is_expected.to eq 'GET, POST, OPTIONS' }
		end

		context 'nonexistent path' do
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

		it do
			is_expected.to eq <<~OUTPUT
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

		describe 'output without color chars' do
			subject { super().gsub(/\e\[(\d+)m/, '') }

			it do
				is_expected.to eq <<~OUTPUT
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
		end
	end
end
