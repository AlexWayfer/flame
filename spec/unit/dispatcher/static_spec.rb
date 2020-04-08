# frozen_string_literal: true

module StaticTest
	class Application < Flame::Application
	end
end

describe Flame::Dispatcher::Static do
	subject(:try_static) { dispatcher.send(:try_static) }

	let(:app) { StaticTest::Application }

	let(:file) { 'test.txt' }

	let(:file_mtime) { File.mtime File.join(__dir__, 'public', file) }

	let(:path) { "/#{file}" }

	let(:env) do
		{
			Rack::REQUEST_METHOD => 'GET',
			Rack::PATH_INFO => path
		}
	end

	let(:dispatcher) { Flame::Dispatcher.new(app, env) }

	context 'when not cached' do
		context 'with static file' do
			it { is_expected.to eq "Test static\n" }
		end

		context 'with symbolic link to file' do
			let(:path) { '/symlink' }

			it { is_expected.to eq "Test static\n" }
		end

		context 'with URL-encoded request' do
			let(:path) do
				'/%D1%82%D0%B5%D1%81%D1%82%D0%BE%D0%B2%D1%8B%D0%B9%20' \
				'%D1%84%D0%B0%D0%B9%D0%BB'
			end

			it { is_expected.to eq "Тестовый файл\n" }
		end

		context 'when request with `+` instead of spaces' do
			let(:path) { '/тестовый+файл' }

			it { is_expected.to eq "Тестовый файл\n" }
		end

		describe 'headers' do
			subject { dispatcher.response[header] }

			before do
				try_static
			end

			describe '`Last-Modified`' do
				let(:header) { 'Last-Modified' }

				it { is_expected.to eq file_mtime.httpdate }
			end

			describe '`Cache-Control`' do
				let(:header) { Rack::CACHE_CONTROL }

				it { is_expected.to eq 'public, max-age=31536000' }
			end
		end
	end

	context 'when cached' do
		let(:env) { super().merge('HTTP_IF_MODIFIED_SINCE' => file_mtime.httpdate) }

		before do
			catch(:halt) { try_static }
		end

		describe 'status' do
			subject { dispatcher.status }

			it { is_expected.to eq 304 }
		end

		describe 'body' do
			subject { dispatcher.body }

			it { is_expected.to be_empty }
		end

		describe '`Cache-Control` header' do
			subject { dispatcher.response[Rack::CACHE_CONTROL] }

			it { is_expected.to eq 'public, max-age=31536000' }
		end
	end

	context 'when file does not exist' do
		let(:path) { '/nonexistent_file' }

		it { is_expected.to be_nil }
	end

	context 'when encoding is invalid' do
		let(:path) { '/%EF%BF%BD%8%EF%BF%BD' }

		it { expect { try_static }.not_to raise_error }
	end

	context 'when file is outside of public directory' do
		before do
			catch(:halt) { try_static }
		end

		let(:path) { '/%2E%2E/%2E%2E/config/example.yml' }

		describe 'status' do
			subject { dispatcher.status }

			it { is_expected.to eq 400 }
		end

		describe 'body' do
			subject { dispatcher.body }

			it { is_expected.to eq 'Bad Request' }
		end
	end
end
