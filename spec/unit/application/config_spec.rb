# frozen_string_literal: true

describe Flame::Application::Config do
	let(:app_class) { Class.new(Flame::Application) }

	let(:config_hash) do
		{
			foo: 1,
			bar: 2,
			baz: proc { 3 },
			another_baz: proc { |x| }
		}
	end

	let(:config) { Flame::Application::Config.new(app_class, config_hash) }

	describe '#[]' do
		describe 'regular values' do
			subject { config[:foo] }

			it { is_expected.to eq 1 }
		end

		describe 'proc values' do
			context 'wihout parameters' do
				subject { config[:baz] }

				it { is_expected.to eq 3 }
			end

			context 'wih parameters' do
				subject { config[:another_baz] }

				it { is_expected.to be_kind_of Proc }
			end
		end
	end

	describe '#load_yaml' do
		let(:yaml) { { foo: 1, bar: 'baz' } }

		subject { app_class.config[key] }

		let(:key) { :example }

		context 'String filename' do
			before do
				app_class.config.load_yaml 'example.yml'
			end

			it { is_expected.to eq yaml }
		end

		context 'Symbol basename' do
			context '`.yml` file' do
				before do
					app_class.config.load_yaml :example
				end

				it { is_expected.to eq yaml }
			end

			context '`.yaml` file' do
				let(:key) { :example2 }

				before do
					app_class.config.load_yaml :example2
				end

				it { is_expected.to eq(foo: 2, bar: 'qux') }
			end
		end

		context 'refined key' do
			let(:key) { :another }

			before do
				app_class.config.load_yaml :example, key: key
			end

			it { is_expected.to eq yaml }
		end

		context ':set option is false' do
			before do
				@loaded = app_class.config.load_yaml :example, set: false
			end

			it { expect(@loaded).to eq yaml }
			it { is_expected.to be_nil }
		end
	end
end
