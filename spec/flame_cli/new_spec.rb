# frozen_string_literal: true

describe 'FlameCLI::New' do
	describe '--help' do
		subject { `#{FLAME_CLI} new --help` }

		it do
			is_expected.to match_words 'Commands:', 'flame new help', 'flame new app'
		end
	end
end
