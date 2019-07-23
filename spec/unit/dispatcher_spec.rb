# frozen_string_literal: true

## Test controller for Dispatcher
class DispatcherController < Flame::Controller
	def index; end

	def foo; end

	def create; end

	def hello(name)
		"Hello, #{name}!"
	end

	def baz(var = nil)
		"Hello, #{var}!"
	end

	def test
		'Route content'
	end

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
class DispatcherApplication < Flame::Application
	mount DispatcherController, '/'
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

	let(:dispatcher) { Flame::Dispatcher.new(DispatcherApplication, env) }

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
		subject(:response) { dispatcher.run!.last }

		subject { response.body }

		context 'existing route' do
			after do
				expect(response.status).to eq 200
			end

			it { is_expected.to eq ['Hello, world!'] }

			context 'nil in after-hook' do
				let(:path) { 'action_with_after_hook' }

				it { is_expected.to eq ['Body of action'] }
			end

			context 'empty body' do
				let(:path) { 'foo' }

				it { is_expected.to eq [''] }
			end

			context 'static file' do
				let(:path) { 'test.txt' }

				it { is_expected.to eq ["Test static\n"] }
			end

			context 'static file in gem' do
				let(:path) { 'favicon.ico' }

				it do
					is_expected.to eq [
						File.read(File.join(__dir__, '../../public/favicon.ico'))
					]
				end
			end

			context 'static file before route executing' do
				let(:path) { 'test' }

				it { is_expected.to eq ["Static file\n"] }
			end

			context 'HEAD method' do
				let(:method) { 'HEAD' }

				it { is_expected.to eq [] }
			end
		end

		context 'not existing route' do
			after do
				expect(response.status).to eq 404
			end

			context 'neither route nor static file was found' do
				let(:path) { 'bar' }

				it { is_expected.to eq ['Not Found'] }
			end

			context 'route with required argument and path without' do
				let(:path) { 'hello' }

				it { is_expected.to eq ['Not Found'] }
			end
		end

		context 'not allowed HTTP-method' do
			after do
				expect(response.status).to eq 405
			end

			let(:method) { 'POST' }

			subject { response.headers['Allow'] }

			it { is_expected.to eq 'GET, OPTIONS' }
		end

		describe 'OPTIONS HTTP-method' do
			let(:method) { 'OPTIONS' }

			describe 'status' do
				subject { response.status }

				context 'existing route' do
					it { is_expected.to eq 200 }
				end

				context 'not existing route' do
					let(:path) { '/hello' }

					it { is_expected.to eq 404 }
				end
			end

			describe 'body' do
				subject { response.body }

				it { is_expected.to eq [''] }
			end

			describe '`Allow` header' do
				subject { response.headers['Allow'] }

				context 'existing route' do
					let(:path) { '/' }

					it { is_expected.to eq 'GET, POST, OPTIONS' }
				end

				context 'not existing route' do
					let(:path) { '/hello' }

					subject { response.headers.key?('Allow') }

					it { is_expected.to be false }
				end

				context 'route with optional parameters' do
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
			before do
				dispatcher.status 404
			end

			subject { dispatcher.response['X-Cascade'] }

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
		subject { dispatcher.params }

		context 'request with Symbol keys' do
			let(:path) { '/hello' }
			let(:query) { 'name=world&when=now' }

			it { is_expected.to eq Hash[name: 'world', when: 'now'] }
			it { is_expected.not_to be dispatcher.request.params }
			it { is_expected.to be dispatcher.params }
		end

		context 'invalid %-encoding query' do
			let(:path) { '/foo' }
			let(:query) { 'bar=%%' }

			it { expect { subject }.not_to raise_error }
		end
	end

	describe '#session' do
		subject { dispatcher.session }

		it { is_expected.to be dispatcher.request.session }
	end

	describe '#config' do
		subject { dispatcher.config }

		it do
			is_expected.to be DispatcherApplication.config
		end
	end

	describe '#halt' do
		before do
			expect { dispatcher.halt(*args) }.to throw_symbol(:halt)
		end

		context 'no arguments' do
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

		context 'new status' do
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

		context 'new status without entity body' do
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

		context 'new status and body' do
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

		context 'new status, body and headers' do
			let(:args) { [200, 'Cats!', 'Content-Type' => 'animal/cat'] }

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

		context 'receiving result of `Controller#redirect`' do
			let(:controller) { DispatcherController.new(dispatcher) }
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
		let(:error) { RuntimeError.new 'Just an example error' }

		before do
			dispatcher.dump_error(error)
		end

		subject do
			dispatcher.instance_variable_get(:@env)[Rack::RACK_ERRORS].string
		end

		it do
			is_expected.to match_words(
				Time.now.strftime('%Y-%m-%d %H:%M:%S'), error.class.name, error.message
			)
		end
	end

	describe '#default_body' do
		describe 'depends on status' do
			subject { dispatcher.default_body }

			before do
				dispatcher.status status
			end

			context 'status 200' do
				let(:status) { 200 }

				it { is_expected.to eq 'OK' }
			end

			context 'status 404' do
				let(:status) { 404 }

				it { is_expected.to eq 'Not Found' }
			end

			context 'status 500' do
				let(:status) { 500 }

				it { is_expected.to eq 'Internal Server Error' }
			end
		end

		describe 'calls from `execute`' do
			let(:path) { 'redirect_from_before' }

			before do
				dispatcher.run!
			end

			subject { dispatcher.request.env[:execute_before_called] }

			it { is_expected.to eq 1 }
		end
	end

	describe 'breaking for invalid %-encoding in requests' do
		let(:path) { '/foo' }
		let(:query) { 'bar=%%' }

		before do
			expect { dispatcher.run! }.not_to raise_error
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
