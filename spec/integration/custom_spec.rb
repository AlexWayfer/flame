# frozen_string_literal: true

require_relative 'app'

## Example of custom controller
class CustomController < Flame::Controller
	def index
		'This is index for nearest routes'
	end

	def foo
		'This is foo'
	end

	def hello(name = 'world')
		"Hello, #{name}!"
	end

	# def page(*path_parts)
	# 	path_parts.join '/'
	# end

	def error
		raise StandardError
	end

	private

	def execute(action)
		@action = action
		super
	rescue StandardError => exception
		@rescued = true
		body default_body
		raise exception
	end

	def not_found
		response.header['Custom-Header'] = 'Hello from not_found'
		halt redirect :foo if request.path.to_s.include? 'redirecting'
		super
	end

	def default_body
		result = "Some page about #{status} code"
		result += "; rescued is #{@rescued}" if status == 500
		result
	end
end

## Mount example controller to app
class IntegrationApp
	mount :custom
end

describe CustomController do
	include Rack::Test::Methods

	describe 'foo' do
		before { get '/custom/foo' }

		describe 'last_response' do
			subject { last_response }

			it { is_expected.to be_ok }

			describe 'body' do
				subject { super().body }

				it { is_expected.to eq 'This is foo' }
			end
		end
	end

	describe 'hello with world' do
		before { get '/custom/hello' }

		describe 'last_response' do
			subject { last_response }

			it { is_expected.to be_ok }

			describe 'body' do
				subject { super().body }

				it { is_expected.to eq 'Hello, world!' }
			end
		end
	end

	describe 'hello with name' do
		before { get '/custom/hello/Alex' }

		describe 'last_response' do
			subject { last_response }

			it { is_expected.to be_ok }

			describe 'body' do
				subject { super().body }

				it { is_expected.to eq 'Hello, Alex!' }
			end
		end
	end

	describe 'custom 404' do
		before { get '/custom/foo/404' }

		describe 'last_response' do
			subject { last_response }

			it { is_expected.to be_not_found }

			describe 'body' do
				subject { super().body }

				it { is_expected.to eq 'Some page about 404 code' }
			end
		end
	end

	describe 'execute custom code for `not_found`' do
		before { get '/custom/404' }

		describe 'last_response' do
			subject { last_response }

			it { is_expected.to be_not_found }

			describe 'Custom-Header' do
				subject { super().headers['Custom-Header'] }

				it { is_expected.to eq 'Hello from not_found' }
			end
		end
	end

	describe 'custom 500' do
		before { get '/custom/error' }

		describe 'last_response' do
			subject { last_response }

			it { is_expected.to be_server_error }

			describe 'body' do
				subject { super().body }

				it { is_expected.to eq 'Some page about 500 code; rescued is true' }
			end
		end
	end

	describe 'status and headers for HEAD request' do
		before { head '/custom/foo' }

		describe 'last_response' do
			subject { last_response }

			it { is_expected.to be_ok }

			describe 'body' do
				subject { super().body }

				it { is_expected.to be_empty }
			end
		end
	end

	describe 'redirect with halt to `foo` from `not_found`' do
		before { get '/custom/redirecting' }

		describe 'last_response' do
			subject { last_response }

			it { is_expected.to be_redirect }

			describe 'body' do
				subject { super().body }

				it { is_expected.to eq 'Some page about 302 code' }
			end
		end
	end
end
