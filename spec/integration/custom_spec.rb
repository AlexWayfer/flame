# frozen_string_literal: true

require_relative 'spec_helper'

module CustomTest
	## Example of custom controller
	class CustomController < Flame::Controller
		def index; end

		def foo
			'This is foo'
		end

		def hello(name = 'world')
			"Hello, #{name}!"
		end

		get ':?key/document',
			def document(key = '')
				return 'I have no document for you.' if key.empty?

				"Here is your #{key} document."
			end

		# def page(*path_parts)
		# 	path_parts.join '/'
		# end

		def error
			raise 'Test'
		end

		def syntax_error
			ERB.new('<% % %>').result(binding)
		end

		def merge_query_parameter(_id)
			path_to :merge_query_parameter, params.merge(lang: 'ru')
		end

		private

		def execute(action)
			@action = action

			return halt redirect :foo if request.path.include? '/old_foo'

			super

			{ a: 1 }
		end

		def not_found
			response.header['Custom-Header'] = 'Hello from not_found'
			halt redirect :foo if request.path.include? 'redirecting'
			super
		end

		def default_body
			result = "Some page about #{status} code"
			result += "; exception is #{@exception.class}" if status == 500
			result
		end

		def server_error(exception)
			@exception = exception
			super
		end
	end

	## Mount example controller to app
	class Application < Flame::Application
		mount :custom

		# puts router.routes
	end
end

describe CustomTest do
	include Rack::Test::Methods

	subject { last_response }

	let(:app) do
		CustomTest::Application.new
	end

	describe 'foo' do
		before { get '/custom/foo' }

		describe 'last_response' do
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
			it { is_expected.to be_ok }

			describe 'body' do
				subject { super().body }

				it { is_expected.to eq 'Hello, Alex!' }
			end
		end
	end

	describe 'document' do
		context 'without key' do
			before { get '/custom/document' }

			describe 'last_response' do
				it { is_expected.to be_ok }

				describe 'body' do
					subject { super().body }

					it { is_expected.to eq 'I have no document for you.' }
				end
			end
		end

		context 'with a key' do
			before { get '/custom/service_agreement/document' }

			describe 'last_response' do
				it { is_expected.to be_ok }

				describe 'body' do
					subject { super().body }

					it { is_expected.to eq 'Here is your service_agreement document.' }
				end
			end
		end
	end

	describe 'custom 404' do
		before { get '/custom/foo/404' }

		describe 'last_response' do
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
			it { is_expected.to be_not_found }

			describe 'Custom-Header' do
				subject { super().headers['Custom-Header'] }

				it { is_expected.to eq 'Hello from not_found' }
			end
		end
	end

	describe 'custom 500' do
		shared_examples 'custom 500' do
			describe 'last_response' do
				it { is_expected.to be_server_error }

				describe 'body' do
					subject { super().body }

					let(:expected_body) do
						"Some page about 500 code; exception is #{exception}"
					end

					it { is_expected.to eq expected_body }
				end
			end
		end

		context 'with regular error' do
			before { get '/custom/error' }

			let(:exception) { RuntimeError }

			it_behaves_like 'custom 500'
		end

		context 'with syntax error' do
			before { get '/custom/syntax_error' }

			let(:exception) { SyntaxError }

			it_behaves_like 'custom 500'
		end
	end

	describe 'status and headers for HEAD request' do
		before { head '/custom/foo' }

		describe 'last_response' do
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
			it { is_expected.to be_redirect }

			describe 'body' do
				subject { super().body }

				it { is_expected.to eq 'Some page about 302 code' }
			end
		end
	end

	describe 'merge query parameter' do
		subject { super().body }

		before { get path }

		let(:path_without) { '/custom/merge_query_parameter/2?foo=bar' }

		shared_examples 'correct path' do
			it { is_expected.to eq "#{path_without}&lang=ru" }
		end

		context 'when does not exist' do
			let(:path) { path_without }

			it_behaves_like 'correct path'
		end

		context 'when exists' do
			let(:path) { "#{path_without}&lang=en" }

			it_behaves_like 'correct path'
		end
	end

	describe 'execute `not_found` through `execute`' do
		before { get '/custom/old_foo' }

		it { is_expected.to be_redirect }

		describe 'location' do
			subject { super().location }

			it { is_expected.to eq '/custom/foo' }
		end
	end
end
