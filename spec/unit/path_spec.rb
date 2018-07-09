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
		subject { Flame::Path.merge(*path_args) }

		context 'Array of Strings' do
			let(:path_args) { %w[foo bar baz] }

			it { is_expected.to eq 'foo/bar/baz' }
		end

		context 'multiple parts as Strings' do
			let(:path_args) { ['/foo/bar', '/baz/bat'] }

			it { is_expected.to eq '/foo/bar/baz/bat' }
		end

		context 'multiple parts as Flame::Path' do
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

		context 'String parameter' do
			let(:path_args) { '/foo/bar' }

			it { is_expected.to eq path_args }
		end

		context 'many path parts' do
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
		let(:path_args) { '/foo/bar/baz' }

		subject { super().parts }

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
		subject { super() + part }

		shared_examples 'correct addition' do
			it do
				is_expected.to eq(
					Flame::Path.new('/foo/:first/:second/:?third/:?fourth')
				)
			end

			it { is_expected.to be_kind_of Flame::Path }

			it { is_expected.not_to be path }

			it { is_expected.not_to be part }
		end

		context 'Flame::Path argument' do
			let(:part) { path_initialize('/:?fourth') }

			it_behaves_like 'correct addition'
		end

		context 'String argument' do
			let(:part) { '/:?fourth' }

			it_behaves_like 'correct addition'
		end
	end

	describe '#<=>' do
		subject { super() <=> other }

		context 'other with less count of path parts' do
			let(:other_args) { '/bar/:first/:second' }

			it { is_expected.to eq(1) }
		end

		context 'other with greater count of path parts' do
			let(:other_args) { '/bar/:first/:second/:?third/:?fourth' }

			it { is_expected.to eq(-1) }
		end

		context 'other with equal count of path parts' do
			let(:other_args) { '/bar/:first/:second/:?third' }

			it { is_expected.to eq(0) }
		end

		context 'other route with arguments' do
			let(:path_args)  { '/route/export_cards' }
			let(:other_args) { '/route/:id' }

			it { is_expected.to eq(1) }
		end
	end

	describe '#==' do
		subject { super() == other }

		context 'other is Path' do
			context 'equal' do
				let(:other) { path_initialize('/foo/:first/:second/:?third') }

				it { is_expected.to be true }
			end

			context 'inequal' do
				let(:other) { path_initialize('/foo/:first/:second') }

				it { is_expected.to be false }
			end
		end

		context 'other is String' do
			context 'equal' do
				let(:other) { '/foo/:first/:second/:?third' }

				it { is_expected.to be true }
			end

			context 'inequal' do
				let(:other) { '/foo/:first/:second' }

				it { is_expected.to be false }
			end
		end
	end

	describe '#adapt' do
		subject { Flame::Path.new(path).adapt(PathController, action).to_s }

		context 'path without action name and parameters' do
			let(:path) { nil }
			let(:action) { :baz }

			it { is_expected.to eq '/baz/:first/:second/:?third' }
		end

		context 'path without parameters' do
			let(:path) { '/foo' }
			let(:action) { :baz }

			it { is_expected.to eq '/foo/:first/:second/:?third' }
		end

		context 'path without some parameters' do
			let(:path) { '/foo/:second' }
			let(:action) { :baz }

			it { is_expected.to eq '/foo/:second/:first/:?third' }
		end

		context 'action without parameters' do
			let(:path) { nil }
			let(:action) { :foo }

			it { is_expected.to eq '/foo' }
		end

		context 'path with all parameters' do
			let(:path) { '/baz/:first/:second/:?third' }
			let(:action) { :baz }

			it { is_expected.to eq path }
		end
	end

	describe '#extract_arguments' do
		subject { super().extract_arguments(other) }

		context 'regular arguments' do
			let(:other_args) { '/foo/bar/baz' }

			it { is_expected.to eq Hash[first: 'bar', second: 'baz'] }
		end

		context 'encoded arguments' do
			let(:other_args) { '/foo/another%20bar/baz' }

			it { is_expected.to eq Hash[first: 'another bar', second: 'baz'] }
		end

		context 'arguments with spaces instead of `+`' do
			let(:other_args) { '/foo/another+bar/baz' }

			it { is_expected.to eq Hash[first: 'another bar', second: 'baz'] }
		end

		context 'missing optional argument before static part' do
			let(:path_args)  { '/foo/:?bar/baz' }
			let(:other_args) { '/foo/baz' }

			it { is_expected.to eq Hash[bar: nil] }
		end

		context 'arguments after optional argument at start' do
			let(:path_args)  { '/:?foo/bar/:?baz/qux/:id' }
			let(:other_args) { '/bar/baz/qux/2' }

			it { is_expected.to eq Hash[foo: nil, baz: 'baz', id: '2'] }
		end

		context 'optional argument after missing optional argument' do
			let(:path_args)  { '/:?foo/bar/:?baz' }
			let(:other_args) { '/bar/baz' }

			it { is_expected.to eq Hash[foo: nil, baz: 'baz'] }
		end

		context 'path with slash at the end' do
			let(:other_args) { '/foo/bar/baz//' }

			it { is_expected.to eq Hash[first: 'bar', second: 'baz'] }
		end
	end

	describe '#assign_arguments' do
		subject { super().assign_arguments(args) }

		context 'all arguments correct' do
			let(:args) { { first: 'bar', second: 'baz' } }

			it { is_expected.to eq '/foo/bar/baz' }
		end

		context 'arguments without one required' do
			let(:args) { { first: 'bar' } }

			it do
				expect { subject }.to raise_error(
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
end
