# frozen_string_literal: true

describe 'FlameCLI::Flame' do
	describe '--help' do
		it 'should print help' do
			`#{FLAME_CLI} --help`
				.should match_words('Commands:', 'flame help', 'flame new ENTITY')
		end
	end
end
