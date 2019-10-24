# frozen_string_literal: true

describe Flame::Config do
	let(:config) { described_class.new(__dir__) }

	describe '#[]' do
		describe 'regular values' do
			before do
				config[:foo] = 1
			end

			subject { config[:foo] }

			it { is_expected.to eq 1 }
		end

		describe 'proc values' do
			context 'wihout parameters' do
				before do
					config[:baz] = proc { 3 }
				end

				subject { config[:baz] }

				it { is_expected.to eq 3 }
			end

			context 'wih parameters' do
				before do
					config[:another_baz] = proc { |x| }
				end

				subject { config[:another_baz] }

				it { is_expected.to be_kind_of Proc }
			end
		end
	end

	describe '#load_yaml' do
		let(:yaml) { { foo: 1, bar: 'baz' } }

		subject { config[key] }

		let(:key) { :example }

		context 'String filename' do
			before do
				config.load_yaml 'example.yml'
			end

			it { is_expected.to eq yaml }
		end

		context 'Symbol basename' do
			context '`.yml` file' do
				before do
					config.load_yaml :example
				end

				it { is_expected.to eq yaml }
			end

			context '`.yaml` file' do
				let(:key) { :example2 }

				before do
					config.load_yaml :example2
				end

				it { is_expected.to eq(foo: 2, bar: 'qux') }
			end
		end

		context 'refined key' do
			let(:key) { :another }

			before do
				config.load_yaml :example, key: key
			end

			it { is_expected.to eq yaml }
		end

		context ':set option is false' do
			before do
				@loaded = config.load_yaml :example, set: false
			end

			it { expect(@loaded).to eq yaml }
			it { is_expected.to be_nil }
		end

		context 'file does not exist' do
			subject do
				config.load_yaml :not_exist
			end

			it do
				expect { subject }.to raise_error(
					Flame::Errors::ConfigFileNotFoundError,
					"Config file 'not_exist.y{a,}ml' not found in 'config/'"
				)
			end
		end
	end
end
