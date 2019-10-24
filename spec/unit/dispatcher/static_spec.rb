# frozen_string_literal: true

module StaticTest
	class Application < Flame::Application
	end
end

describe Flame::Dispatcher::Static do
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

	subject(:try_static) { dispatcher.send(:try_static) }

	context 'not cached' do
		context 'static file' do
			it { is_expected.to eq "Test static\n" }
		end

		context 'symbolic link to file' do
			let(:path) { '/symlink' }

			it { is_expected.to eq "Test static\n" }
		end

		context 'URL-encoded request' do
			let(:path) do
				'/%D1%82%D0%B5%D1%81%D1%82%D0%BE%D0%B2%D1%8B%D0%B9%20' \
				'%D1%84%D0%B0%D0%B9%D0%BB'
			end

			it { is_expected.to eq "Тестовый файл\n" }
		end

		context 'request with `+` instead of spaces' do
			let(:path) { '/тестовый+файл' }

			it { is_expected.to eq "Тестовый файл\n" }
		end

		describe 'headers' do
			before do
				try_static
			end

			subject { dispatcher.response[header] }

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

	context 'cached' do
		let(:env) { super().merge('HTTP_IF_MODIFIED_SINCE' => file_mtime.httpdate) }

		before do
			expect { try_static }.to throw_symbol(:halt)
		end

		context 'cached file' do
			describe 'status' do
				subject { dispatcher.status }

				it { is_expected.to eq 304 }
			end

			describe 'body' do
				subject { dispatcher.body }

				it { is_expected.to be_empty }
			end
		end

		describe '`Cache-Control` header' do
			subject { dispatcher.response[Rack::CACHE_CONTROL] }

			it { is_expected.to eq 'public, max-age=31536000' }
		end
	end

	context 'nonexistent file' do
		let(:path) { '/nonexistent_file' }

		it { is_expected.to be_nil }
	end

	context 'invalid encoding' do
		let(:path) { '/%EF%BF%BD%8%EF%BF%BD' }

		it { expect { subject }.not_to raise_error }
	end

	context 'file outside public directory' do
		before do
			expect { try_static }.to throw_symbol(:halt)
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
