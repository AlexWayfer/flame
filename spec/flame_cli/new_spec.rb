# frozen_string_literal: true

describe 'FlameCLI::New' do
	describe '--help' do
		it 'should print help' do
			`#{FLAME_CLI} new --help`
				.should match_words('Commands:', 'flame new help', 'flame new app')
		end
	end
end
