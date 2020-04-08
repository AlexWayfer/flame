# frozen_string_literal: true

## https://github.com/rubocop-hq/rubocop-rspec/issues/889
# rubocop:disable RSpec/DescribeClass
describe 'Flame::VERSION' do
	# rubocop:enable RSpec/DescribeClass
	subject { Object.const_get(self.class.description) }

	it { is_expected.to be_kind_of String }

	it { is_expected.not_to be_empty }
end
