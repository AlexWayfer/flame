# frozen_string_literal: true

describe 'Flame::VERSION' do
	subject { Object.const_get(self.class.description) }

	it { is_expected.to be_kind_of String }

	it { is_expected.not_to be_empty }
end
