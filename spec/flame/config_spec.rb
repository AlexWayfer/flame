# frozen_string_literal: true

describe Flame::Config do
	let(:config) { described_class.new(__dir__) }

	describe '#[]' do
		describe 'regular values' do
			subject { config[:foo] }

			before do
				config[:foo] = 1
			end

			it { is_expected.to eq 1 }
		end

		describe 'proc values' do
			context 'without parameters' do
				subject { config[:baz] }

				before do
					config[:baz] = proc { 3 }
				end

				it { is_expected.to eq 3 }
			end

			context 'with parameters' do
				subject { config[:another_baz] }

				before do
					config[:another_baz] = proc { |x| x }
				end

				it { is_expected.to be_a Proc }
			end
		end
	end

	describe '#load_yaml' do
		subject { config[key] }

		let(:yaml) { { foo: 1, bar: 'baz' } }

		let(:key) { :example }

		context 'with String filename' do
			before do
				config.load_yaml 'example.yml'
			end

			it { is_expected.to eq yaml }
		end

		context 'with Symbol basename' do
			context 'with `.yml` file' do
				before do
					config.load_yaml :example
				end

				it { is_expected.to eq yaml }
			end

			context 'with `.yaml` file' do
				let(:key) { :example2 }

				before do
					config.load_yaml :example2
				end

				it { is_expected.to eq(foo: 2, bar: 'qux') }
			end

			context 'with anchors inside' do
				let(:key) { :example3 }

				let(:expected_content) do
					{
						'.default' => { foo: 3, bar: 'quux' },
						'production' => { foo: 3, bar: 'quux' }
					}
				end

				before do
					config.load_yaml :example3
				end

				it { is_expected.to eq expected_content }
			end
		end

		context 'with refined key' do
			let(:key) { :another }

			before do
				config.load_yaml :example, key: key
			end

			it { is_expected.to eq yaml }
		end

		context 'when `:set` option is false' do
			let(:result) { config.load_yaml :example, set: false }

			before { result }

			it { is_expected.to be_nil }

			describe 'result' do
				subject { result }

				it { is_expected.to eq yaml }
			end
		end

		context 'when file does not exist' do
			subject(:result) { config.load_yaml :not_exist }

			it do
				expect { result }.to raise_error(
					Flame::Errors::ConfigFileNotFoundError,
					"Config file 'not_exist.y{a,}ml' not found in 'config/'"
				)
			end
		end

		context 'when `:required` option is false' do
			subject(:result) { config.load_yaml :not_exist, required: false }

			it { expect { result }.not_to raise_error }
		end
	end
end
