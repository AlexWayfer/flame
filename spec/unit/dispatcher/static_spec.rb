# frozen_string_literal: true

class StaticApp < Flame::Application
end

describe Flame::Dispatcher::Static do
	before do
		@app = StaticApp.new
		@file = 'test.txt'
		@env = {
			Rack::REQUEST_METHOD => 'GET',
			Rack::PATH_INFO => "/#{@file}"
		}
		@dispatcher = Flame::Dispatcher.new(@app, @env)
		@result = @dispatcher.send(:try_static)
	end

	shared 'response with Cache-Control' do
		should 'have Cache-Control with public and max-age value' do
			@dispatcher.response[Rack::CACHE_CONTROL]
				.should.equal 'public, max-age=31536000'
		end
	end

	describe 'not cached' do
		it 'should return content of static file ' \
		   'with Cache-Control as public and max-age' do
			@result.should.equal "Test static\n"
		end

		it 'should return content of symbolic link to file' do
			@env[Rack::PATH_INFO] = '/symlink'
			dispatcher = Flame::Dispatcher.new(@app, @env)
			dispatcher.send(:try_static).should.equal "Test static\n"
		end

		it 'should return with Last-Modified' do
			file_mtime = File.mtime File.join(__dir__, 'public', @file)
			@dispatcher.response['Last-Modified'].should.equal file_mtime.httpdate
		end

		behaves_like 'response with Cache-Control'
	end

	describe 'cached' do
		before do
			file_mtime = File.mtime File.join(__dir__, 'public', @file)
			@env['HTTP_IF_MODIFIED_SINCE'] = file_mtime.httpdate
			@dispatcher = Flame::Dispatcher.new(@app, @env)
			catch(:halt) { @dispatcher.send(:try_static) }
		end

		it 'should return 304 with Cache-Control as public and max-age ' \
		   'for cached file' do
			@dispatcher.status.should.equal 304
			@dispatcher.body.should.equal ''
		end

		behaves_like 'response with Cache-Control'
	end

	it 'should not found non-existing file' do
		@env[Rack::PATH_INFO] = '/non-existing_file'
		dispatcher = Flame::Dispatcher.new(@app, @env)
		dispatcher.send(:try_static).should.equal nil
	end
end
