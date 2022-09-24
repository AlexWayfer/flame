# frozen_string_literal: true

describe Flame::Dispatcher::Request do
	subject(:request) { described_class.new(env) }

	let(:method) { :PATCH }
	let(:query) { '' }

	let(:env) do
		{
			Rack::REQUEST_METHOD => 'POST',
			Rack::PATH_INFO => '/hello/great/world',
			Rack::QUERY_STRING => query,
			Rack::RACK_INPUT => StringIO.new("_method=#{method}"),
			Rack::RACK_REQUEST_FORM_HASH => { '_method' => method.to_s }
		}
	end

	it { is_expected.to be_a Rack::Request }

	describe '#path' do
		subject { request.path }

		it { is_expected.to be_a Flame::Path }
		it { is_expected.to eq '/hello/great/world' }
	end

	describe '#http_method' do
		subject(:http_method) { request.http_method }

		describe 'priority to return HTTP-method from parameter' do
			it { is_expected.to eq :PATCH }
		end

		it { is_expected.to be_a Symbol }

		context 'when input is downcased' do
			let(:method) { :put }

			it { is_expected.to eq :PUT }
		end

		context 'with invalid %-encoding query' do
			let(:query) { 'bar=%%' }

			it { expect { http_method }.not_to raise_error }
		end
	end

	describe '#headers' do
		subject(:headers) { request.headers }

		let(:env) do
			super().merge(
				'HTTP_VERSION' => 'HTTP/1.1',
				'HTTP_CACHE_CONTROL' => 'max-age=0'
			)
		end

		it { is_expected.to be_an_instance_of(Hash) }

		it do
			expect(headers).to include(
				'Version' => 'HTTP/1.1',
				'Cache-Control' => 'max-age=0'
			)
		end
	end
end
