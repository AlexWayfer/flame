# frozen_string_literal: true

describe Flame::Controller::Cookies do
	subject(:cookies) { described_class.new(request.cookies, response) }

	let(:env) do
		{
			'HTTP_COOKIE' => 'foo=bar; baz=bat'
		}
	end

	let(:request) { Flame::Dispatcher::Request.new(env) }
	let(:response) { Flame::Dispatcher::Response.new }

	describe '#initialize' do
		it { expect { cookies }.not_to raise_error }
	end

	describe '#[]' do
		subject { cookies[key] }

		context 'with String key' do
			let(:key) { 'foo' }

			it { is_expected.to eq 'bar' }
		end

		context 'with Symbol key' do
			let(:key) { :baz }

			it { is_expected.to eq 'bat' }
		end
	end

	describe '#[]=' do
		subject { response[Rack::SET_COOKIE] }

		before do
			cookies[:abc] = cookie_value
		end

		describe 'setting cookie' do
			let(:cookie_value) { 'xyz' }

			it { is_expected.to include 'abc=xyz;' }

			describe 'accepting options' do
				let(:max_age) { 30 * 24 * 60 * 60 }
				let(:cookie_value) { { value: 'xyz', max_age: max_age } }

				it { is_expected.to include "abc=xyz; max-age=#{max_age}"}
			end
		end

		describe 'deleting cookie for response by nil value' do
			let(:cookie_value) { nil }

			before do
				cookies[:abc] = 'xyz'
				cookies[:abc] = nil
			end

			it { is_expected.to include 'abc=;' }
		end
	end
end
