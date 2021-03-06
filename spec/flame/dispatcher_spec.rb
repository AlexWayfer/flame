# frozen_string_literal: true

module DispatcherTest
	## Test controller for Dispatcher
	class IndexController < Flame::Controller
		def index; end

		def foo; end

		def create; end

		def hello(name)
			"Hello, #{name}!"
		end

		def baz(var = nil); end

		def test; end

		def action_with_after_hook
			'Body of action'
		end

		def redirect_from_before; end

		protected

		def execute(action)
			request.env[:execute_before_called] ||= 0
			request.env[:execute_before_called] += 1
			halt redirect :foo if action == :redirect_from_before
			super
			nil if action == :action_with_after_hook
		end
	end

	## Test application for Dispatcher
	class Application < Flame::Application
		mount IndexController, '/'
	end
end

describe Flame::Dispatcher do
	let(:method) { 'GET' }
	let(:path) { '/hello/world' }
	let(:query) { nil }

	let(:env) do
		{
			Rack::REQUEST_METHOD => method,
			Rack::PATH_INFO => path,
			Rack::RACK_INPUT => StringIO.new,
			Rack::RACK_ERRORS => StringIO.new,
			Rack::QUERY_STRING => query
		}
	end

	let(:dispatcher) { described_class.new(DispatcherTest::Application, env) }

	describe 'attrs' do
		describe 'request reader' do
			subject { dispatcher.request }

			it { is_expected.to be_instance_of Flame::Dispatcher::Request }
		end

		describe 'response reader' do
			subject { dispatcher.response }

			it { is_expected.to be_instance_of Flame::Dispatcher::Response }
		end
	end

	describe '#initialize' do
		describe 'instance variables' do
			subject { dispatcher.instance_variable_get(instance_variable) }

			describe '@app_class' do
				let(:instance_variable) { :@app_class }

				it { is_expected.to eq DispatcherTest::Application }
			end

			describe '@env' do
				let(:instance_variable) { :@env }

				it { is_expected.to eq env }
			end
		end

		describe 'request from env' do
			subject { dispatcher.request.env }

			it { is_expected.to eq env }
		end

		describe 'response' do
			subject { dispatcher.response }

			it { is_expected.to be_instance_of Flame::Dispatcher::Response }
		end
	end

	describe '#run!' do
		subject(:result) { body }

		let(:response) { dispatcher.run! }
		let(:status) { response[0] }
		let(:headers) { response[1] }
		let(:body) { response[2] }

		shared_examples 'status is correct' do
			describe 'status' do
				subject { status }

				it { is_expected.to eq expected_status }
			end
		end

		context 'when route exists' do
			let(:expected_status) { 200 }

			it { is_expected.to eq ['Hello, world!'] }

			include_examples 'status is correct'

			context 'with nil in after-hook' do
				let(:path) { 'action_with_after_hook' }

				it { is_expected.to eq ['Body of action'] }

				include_examples 'status is correct'
			end

			context 'when body is empty' do
				let(:path) { 'foo' }

				it { is_expected.to eq [''] }

				include_examples 'status is correct'
			end

			context 'with static file' do
				let(:path) { 'test.txt' }

				it { is_expected.to eq ["Test static\n"] }

				include_examples 'status is correct'
			end

			context 'with static file in gem' do
				let(:path) { 'favicon.ico' }
				let(:real_file_path) { "#{__dir__}/../../public/#{path}" }

				it { is_expected.to eq [File.read(real_file_path)] }

				include_examples 'status is correct'
			end

			context 'with static file before route executing' do
				let(:path) { 'test' }

				it { is_expected.to eq ["Static file\n"] }

				include_examples 'status is correct'
			end

			context 'with HEAD method' do
				let(:method) { 'HEAD' }

				it { is_expected.to eq [] }

				include_examples 'status is correct'
			end
		end

		context 'when route does not exist' do
			let(:expected_status) { 404 }

			context 'when neither route nor static file was found' do
				let(:path) { 'bar' }

				it { is_expected.to eq ['Not Found'] }

				include_examples 'status is correct'
			end

			context 'when route with required argument and without path' do
				let(:path) { 'hello' }

				it { is_expected.to eq ['Not Found'] }

				include_examples 'status is correct'
			end
		end

		context 'when HTTP-method is not allowed' do
			subject { headers['Allow'] }

			let(:expected_status) { 405 }
			let(:method) { 'POST' }

			it { is_expected.to eq 'GET, OPTIONS' }

			include_examples 'status is correct'
		end

		context 'when HTTP-method is OPTIONS' do
			let(:method) { 'OPTIONS' }

			describe 'status' do
				subject { status }

				context 'when route exists' do
					it { is_expected.to eq 200 }
				end

				context 'when route does not exist' do
					let(:path) { '/hello' }

					it { is_expected.to eq 404 }
				end
			end

			describe 'body' do
				subject { body }

				it { is_expected.to eq [''] }
			end

			describe '`Allow` header' do
				subject { headers['Allow'] }

				context 'when route exists' do
					let(:path) { '/' }

					it { is_expected.to eq 'GET, POST, OPTIONS' }
				end

				context 'when route does not exist' do
					subject { headers.key?('Allow') }

					let(:path) { '/hello' }

					it { is_expected.to be false }
				end

				context 'when route with optional parameters' do
					let(:path) { '/baz' }

					it { is_expected.to eq 'GET, OPTIONS' }
				end
			end
		end
	end

	describe '#status' do
		subject { dispatcher.status }

		describe 'default' do
			it { is_expected.to eq 200 }
		end

		describe 'setting' do
			before do
				dispatcher.status 101
			end

			it { is_expected.to eq 101 }

			describe 'in response' do
				subject { dispatcher.response.status }

				it { is_expected.to eq 101 }
			end
		end

		describe 'X-Cascade header for 404 status' do
			subject { dispatcher.response['X-Cascade'] }

			before do
				dispatcher.status 404
			end

			it { is_expected.to eq 'pass' }
		end
	end

	describe '#body' do
		subject { dispatcher.body }

		before do
			dispatcher.body 'Hello!'
		end

		it { is_expected.to eq 'Hello!' }
	end

	describe '#params' do
		subject(:params) { dispatcher.params }

		describe 'keys are Symbols' do
			let(:path) { '/hello' }
			let(:query) { 'name=world&when=now' }

			it { is_expected.to eq(name: 'world', when: 'now') }
			it { is_expected.not_to be dispatcher.request.params }
			it { is_expected.to be dispatcher.params }
		end

		context 'with invalid %-encoding query' do
			let(:path) { '/foo' }
			let(:query) { 'bar=%%' }

			it { expect { params }.not_to raise_error }
		end
	end

	describe '#session' do
		subject { dispatcher.session }

		it { is_expected.to be dispatcher.request.session }
	end

	describe '#config' do
		subject { dispatcher.config }

		let(:expected_config) do
			dispatcher.instance_variable_get(:@app_class).config
		end

		it { is_expected.to be expected_config }
	end

	describe '#halt' do
		before do
			catch(:halt) { dispatcher.halt(*args) }
		end

		context 'with no arguments' do
			let(:args) { [] }

			describe 'status' do
				subject { dispatcher.status }

				it { is_expected.to eq 200 }
			end

			describe 'body' do
				subject { dispatcher.body }

				it { is_expected.to eq dispatcher.default_body }
			end
		end

		context 'with a new status' do
			let(:args) { [500] }

			describe 'status' do
				subject { dispatcher.status }

				it { is_expected.to eq 500 }
			end

			describe 'body' do
				subject { dispatcher.body }

				it { is_expected.to eq dispatcher.default_body }
			end
		end

		context 'with a new status without entity body' do
			let(:args) { [101] }

			describe 'status' do
				subject { dispatcher.status }

				it { is_expected.to eq 101 }
			end

			describe 'body' do
				subject { dispatcher.body }

				it { is_expected.to be_empty }
			end
		end

		context 'with new status and body' do
			let(:args) { [404, 'Nobody here'] }

			describe 'status' do
				subject { dispatcher.status }

				it { is_expected.to eq 404 }
			end

			describe 'body' do
				subject { dispatcher.body }

				it { is_expected.to eq 'Nobody here' }
			end
		end

		context 'with new status, body and headers' do
			let(:args) { [200, 'Cats!', { 'Content-Type' => 'animal/cat' }] }

			describe 'status' do
				subject { dispatcher.status }

				it { is_expected.to eq 200 }
			end

			describe 'body' do
				subject { dispatcher.body }

				it { is_expected.to eq 'Cats!' }
			end

			describe 'headers' do
				subject { dispatcher.response.headers }

				it { is_expected.to include 'Content-Type' => 'animal/cat' }
			end
		end

		context 'with result of `Controller#redirect`' do
			let(:controller) { DispatcherTest::IndexController.new(dispatcher) }
			let(:args) { [controller.redirect('http://example.com', 301)] }

			describe 'status' do
				subject { dispatcher.status }

				it { is_expected.to eq 301 }
			end

			describe 'location' do
				subject { dispatcher.response.location }

				it { is_expected.to eq 'http://example.com' }
			end
		end
	end

	describe '#dump_error' do
		subject do
			dispatcher.instance_variable_get(:@env)[Rack::RACK_ERRORS].string
		end

		before do
			dispatcher.dump_error(error)
		end

		let(:error) { RuntimeError.new 'Just an example error' }

		let(:expected_words) do
			[Time.now.strftime('%Y-%m-%d %H:%M:%S'), error.class.name, error.message]
		end

		it { is_expected.to match_words expected_words }
	end

	describe '#default_body' do
		describe 'depends on status' do
			subject { dispatcher.default_body }

			before do
				dispatcher.status status
			end

			context 'when status is 200' do
				let(:status) { 200 }

				it { is_expected.to eq 'OK' }
			end

			context 'when status is 404' do
				let(:status) { 404 }

				it { is_expected.to eq 'Not Found' }
			end

			context 'when status is 500' do
				let(:status) { 500 }

				it { is_expected.to eq 'Internal Server Error' }
			end
		end

		describe 'calls from `execute`' do
			subject { dispatcher.request.env[:execute_before_called] }

			let(:path) { 'redirect_from_before' }

			before do
				dispatcher.run!
			end

			it { is_expected.to eq 1 }
		end
	end

	describe 'breaking for invalid %-encoding in requests' do
		let(:path) { '/foo' }
		let(:query) { 'bar=%%' }

		before do
			dispatcher.run!
		end

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
