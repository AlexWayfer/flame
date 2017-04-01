# frozen_string_literal: true

describe Flame::Request do
	before do
		@env = {
			Rack::REQUEST_METHOD => 'POST',
			Rack::PATH_INFO => '/hello/great/world',
			Rack::RACK_INPUT => StringIO.new('_method=PATCH'),
			Rack::RACK_REQUEST_FORM_HASH => { '_method' => 'PATCH' }
		}
		@request = Flame::Request.new(@env)
	end

	it 'should be Rack::Request child' do
		@request.should.be.kind_of Rack::Request
	end

	describe '#path_parts' do
		it 'should return parts of requested path' do
			@request.path_parts.should.equal %w(hello great world)
		end
	end

	describe '#http_method' do
		it 'should have priority to return HTTP-method from parameter' do
			@request.http_method.should.equal 'PATCH'
		end
	end
end
