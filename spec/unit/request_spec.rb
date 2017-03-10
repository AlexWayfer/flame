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

	it 'should split path to parts' do
		@request.path_parts.should.equal %w(hello great world)
	end

	it 'should overwrite HTTP-method by parameter' do
		@request.http_method.should.equal 'PATCH'
	end
end
