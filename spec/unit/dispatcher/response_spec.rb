# frozen_string_literal: true

describe Flame::Dispatcher::Response do
	before do
		@response = Flame::Dispatcher::Response.new
	end

	it 'should be Rack::Response child' do
		@response.should.be.kind_of Rack::Response
	end

	describe '#content_type=' do
		it 'should set Content-Type header with given value' do
			@response.content_type = 'text/html'
			@response.content_type.should.equal 'text/html'
		end

		it 'should set Content-Type header by extension' do
			@response.content_type = '.css'
			@response.content_type.should.equal 'text/css'
		end
	end
end
