# frozen_string_literal: true

describe 'FlameCLI::Flame' do
	describe '--help' do
		subject { `#{FLAME_CLI} --help` }

		it do
			is_expected.to match_words 'Commands:', 'flame help', 'flame new ENTITY'
		end
	end
end
