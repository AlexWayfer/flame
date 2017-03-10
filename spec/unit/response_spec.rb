# frozen_string_literal: true
describe Flame::Response do
	before do
		@response = Flame::Response.new
	end

	it 'should be Rack::Response child' do
		@response.should.be.kind_of Rack::Response
	end
end
