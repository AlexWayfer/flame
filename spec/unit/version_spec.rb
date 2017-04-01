# frozen_string_literal: true

describe 'Flame::VERSION' do
	it 'should be String' do
		Flame::VERSION.should.be.kind_of String
	end

	it 'should not be empty' do
		Flame::VERSION.should.not.be.empty
	end
end
