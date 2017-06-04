# frozen_string_literal: true

describe 'Flame' do
	it 'should require all files when flame required' do
		files = Dir[
			File.join(__dir__, '..', '..', 'lib', 'flame', '**', '*')
		]
		files.select! do |file|
			File.file? file
		end
		files.each do |file|
			(require file).should.equal false
		end
	end
end
