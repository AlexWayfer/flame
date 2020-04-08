# frozen_string_literal: true

class PathController
	def foo; end

	def bar(first); end

	def baz(first, second, third = nil); end
end

describe Flame::Path do
	def path_initialize(*args)
		Flame::Path.new(*args)
	end

	subject(:path) { path_initialize(*path_args) }

	let(:other)    { path_initialize(*other_args) }

	let(:path_args) { '/foo/:first/:second/:?third' }

	describe '.merge' do
		subject { described_class.merge(*path_args) }

		context 'with Array of Strings' do
			let(:path_args) { %w[foo bar baz] }

			it { is_expected.to eq 'foo/bar/baz' }
		end

		context 'with multiple parts as Strings' do
			let(:path_args) { ['/foo/bar', '/baz/bat'] }

			it { is_expected.to eq '/foo/bar/baz/bat' }
		end

		context 'with multiple parts as Flame::Path' do
			let(:path_args) do
				[path_initialize('/foo/bar'), path_initialize('/baz/bat')]
			end

			it { is_expected.to eq '/foo/bar/baz/bat' }
		end

		describe 'without extra slashes' do
			let(:path_args) { ['///foo/bar//', '//baz/bat///'] }

			it { is_expected.to eq '/foo/bar/baz/bat/' }
		end
	end

	describe '#initialize' do
		subject { super().to_s }

		context 'with String parameter' do
			let(:path_args) { '/foo/bar' }

			it { is_expected.to eq path_args }
		end

		context 'with many path parts' do
			let(:path_args) { ['/foo', '/bar', 'baz'] }

			it { is_expected.to eq '/foo/bar/baz' }
		end

		describe 'Flame::Path parameter' do
			subject { path }

			let(:path_args) { path_initialize('/foo/bar') }

			it { is_expected.to eq path_args }

			it { is_expected.not_to be path_args }
		end
	end

	describe '#parts' do
		subject { super().parts }

		let(:path_args) { '/foo/bar/baz' }

		it { is_expected.to eq %w[foo bar baz] }
	end

	describe '#freeze' do
		describe '#to_s' do
			subject { super().to_s }

			it { is_expected.to be_frozen }
		end

		describe 'path parts' do
			subject { super().parts }

			it { is_expected.to all be_frozen }
			it { is_expected.to be_frozen }
		end
	end

	describe '#+' do
		subject { path + part }

		shared_examples 'correct addition' do
			let(:expected_result) do
				described_class.new('/foo/:first/:second/:?third/:?fourth')
			end

			it { is_expected.to eq expected_result }

			it { is_expected.to be_kind_of described_class }

			it { is_expected.not_to be path }

			it { is_expected.not_to be part }
		end

		context 'with Flame::Path argument' do
			let(:part) { path_initialize('/:?fourth') }

			it_behaves_like 'correct addition'
		end

		context 'with String argument' do
			let(:part) { '/:?fourth' }

			it_behaves_like 'correct addition'
		end
	end

	describe '#<=>' do
		subject { super() <=> other }

		context 'when other with less count of path parts' do
			let(:other_args) { '/bar/:first/:second' }

			it { is_expected.to eq(1) }
		end

		context 'when other with greater count of path parts' do
			let(:other_args) { '/bar/:first/:second/:?third/:?fourth' }

			it { is_expected.to eq(-1) }
		end

		context 'when other with equal count of path parts' do
			let(:other_args) { '/bar/:first/:second/:?third' }

			it { is_expected.to eq(0) }
		end

		context 'when other route with arguments' do
			let(:path_args)  { '/route/export_cards' }
			let(:other_args) { '/route/:id' }

			it { is_expected.to eq(1) }
		end
	end

	describe '#==' do
		subject { super() == other }

		context 'when other is Path' do
			context 'when equal' do
				let(:other) { path_initialize('/foo/:first/:second/:?third') }

				it { is_expected.to be true }
			end

			context 'when inequal' do
				let(:other) { path_initialize('/foo/:first/:second') }

				it { is_expected.to be false }
			end
		end

		context 'when other is String' do
			context 'when equal' do
				let(:other) { '/foo/:first/:second/:?third' }

				it { is_expected.to be true }
			end

			context 'when inequal' do
				let(:other) { '/foo/:first/:second' }

				it { is_expected.to be false }
			end
		end
	end

	describe '#adapt' do
		subject { described_class.new(path).adapt(PathController, action).to_s }

		context 'with path without action name and parameters' do
			let(:path) { nil }
			let(:action) { :baz }

			it { is_expected.to eq '/baz/:first/:second/:?third' }
		end

		context 'with path without parameters' do
			let(:path) { '/foo' }
			let(:action) { :baz }

			it { is_expected.to eq '/foo/:first/:second/:?third' }
		end

		context 'with path without some parameters' do
			let(:path) { '/foo/:second' }
			let(:action) { :baz }

			it { is_expected.to eq '/foo/:second/:first/:?third' }
		end

		context 'with action without parameters' do
			let(:path) { nil }
			let(:action) { :foo }

			it { is_expected.to eq '/foo' }
		end

		context 'with path with all parameters' do
			let(:path) { '/baz/:first/:second/:?third' }
			let(:action) { :baz }

			it { is_expected.to eq path }
		end
	end

	describe '#extract_arguments' do
		subject { super().extract_arguments(other) }

		context 'with regular arguments' do
			let(:other_args) { '/foo/bar/baz' }

			it { is_expected.to eq Hash[first: 'bar', second: 'baz'] }
		end

		context 'with encoded arguments' do
			let(:other_args) { '/foo/another%20bar/baz' }

			it { is_expected.to eq Hash[first: 'another bar', second: 'baz'] }
		end

		context 'with arguments with spaces instead of `+`' do
			let(:other_args) { '/foo/another+bar/baz' }

			it { is_expected.to eq Hash[first: 'another bar', second: 'baz'] }
		end

		context 'with missing optional argument before static part' do
			let(:path_args)  { '/foo/:?bar/baz' }
			let(:other_args) { '/foo/baz' }

			it { is_expected.to eq Hash[bar: nil] }
		end

		context 'with arguments after optional argument at start' do
			let(:path_args)  { '/:?foo/bar/:?baz/qux/:id' }
			let(:other_args) { '/bar/baz/qux/2' }

			it { is_expected.to eq Hash[foo: nil, baz: 'baz', id: '2'] }
		end

		context 'with optional argument after missing optional argument' do
			let(:path_args)  { '/:?foo/bar/:?baz' }
			let(:other_args) { '/bar/baz' }

			it { is_expected.to eq Hash[foo: nil, baz: 'baz'] }
		end

		context 'with path with slash at the end' do
			let(:other_args) { '/foo/bar/baz//' }

			it { is_expected.to eq Hash[first: 'bar', second: 'baz'] }
		end
	end

	describe '#assign_arguments' do
		subject(:result) { path.assign_arguments(args) }

		context 'when all arguments are correct' do
			let(:args) { { first: 'bar', second: 'baz' } }

			it { is_expected.to eq '/foo/bar/baz' }
		end

		context 'when arguments without one required' do
			let(:args) { { first: 'bar' } }

			it do
				expect { result }.to raise_error(
					Flame::Errors::ArgumentNotAssignedError,
					%r{':second'[\w\s]+'/foo/:first/:second/:\?third'}
				)
			end
		end
	end

	describe '#to_s' do
		subject { super().to_s }

		let(:path_args) { ['/foo', 'bar', '/baz'] }

		it { is_expected.to eq '/foo/bar/baz' }
	end

	describe '#to_str' do
		subject { super().to_str }

		let(:path_args) { ['/foo', 'bar', '/baz'] }

		it { is_expected.to eq '/foo/bar/baz' }

		describe 'concatenate Flame::Path object to Strings' do
			subject { string + path }

			let(:string)    { '/foo' }
			let(:path_args) { ['/bar', 'baz'] }

			it { is_expected.to eq '/foo/bar/baz' }
		end
	end

	describe '#to_routes_with_endpoint' do
		subject(:result) { path.to_routes_with_endpoint }

		let(:routes)   { result.first }
		let(:endpoint) { result.last }

		let(:path_args) { '/foo/bar/baz' }

		describe 'routes' do
			subject { routes }

			it { is_expected.to eq('foo' => { 'bar' => { 'baz' => {} } }) }
		end

		describe 'endpoint' do
			subject { endpoint }

			it { is_expected.to eq({}) }
			it { is_expected.to be routes.dig(*path.parts) }
		end
	end

	describe '#include?' do
		subject { super().include?(*args) }

		let(:path_args) { '/foo/bar/baz' }

		context 'with existing part' do
			let(:args) { '/bar/baz' }

			it { is_expected.to be true }
		end

		context 'with nonexistent part' do
			let(:args) { '/barr' }

			it { is_expected.to be false }
		end
	end
end
