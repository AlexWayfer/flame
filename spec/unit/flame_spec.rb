# frozen_string_literal: true

describe 'Flame' do
	it 'should require all files when flame required' do
		Dir[
			File.join(__dir__, '..', '..', 'lib', 'flame', '**', '*')
		].each do |file|
			(require file).should.equal false
		end
	end
end
