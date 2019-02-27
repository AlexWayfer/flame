# frozen_string_literal: true

describe Flame::Controller::Cookies do
	let(:env) do
		{
			'HTTP_COOKIE' => 'foo=bar; baz=bat'
		}
	end

	let(:request) { Flame::Dispatcher::Request.new(env) }
	let(:response) { Flame::Dispatcher::Response.new }

	subject(:cookies) do
		Flame::Controller::Cookies.new(request.cookies, response)
	end

	describe '#initialize' do
		it { expect { subject }.not_to raise_error }
	end

	describe '#[]' do
		subject { cookies[key] }

		context 'String key' do
			let(:key) { 'foo' }

			it { is_expected.to eq 'bar' }
		end

		context 'Symbol key' do
			let(:key) { :baz }

			it { is_expected.to eq 'bat' }
		end
	end

	describe '#[]=' do
		before do
			cookies[:abc] = cookie_value
		end

		subject { response[Rack::SET_COOKIE] }

		describe 'setting cookie' do
			let(:cookie_value) { 'xyz' }

			it { is_expected.to include 'abc=xyz;' }
		end

		describe 'deleting cookie for response by nil value' do
			let(:cookie_value) { nil }

			before do
				cookies[:abc] = 'xyz'
				is_expected.to include 'abc=xyz;'
			end

			it { is_expected.to include 'abc=;' }
		end
	end
end
