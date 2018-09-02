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
		super
	end

	def not_found
		response.header['Custom-Header'] = 'Hello from not_found'
		halt redirect :foo if request.path.to_s.include? 'redirecting'
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
		shared_examples 'custom 500' do
			describe 'last_response' do
				subject { last_response }

				it { is_expected.to be_server_error }

				describe 'body' do
					subject { super().body }

					it do
						is_expected.to eq(
							"Some page about 500 code; exception is #{exception}"
						)
					end
				end
			end
		end

		context 'regular error' do
			before { get '/custom/error' }

			let(:exception) { RuntimeError }

			it_behaves_like 'custom 500'
		end

		context 'syntax error' do
			before { get '/custom/syntax_error' }

			let(:exception) { SyntaxError }

			it_behaves_like 'custom 500'
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

	describe 'merge query parameter' do
		before { get path }

		let(:path_without) { '/custom/merge_query_parameter/2?foo=bar' }

		subject { last_response.body }

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
end
