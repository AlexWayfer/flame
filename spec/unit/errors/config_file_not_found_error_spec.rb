# frozen_string_literal: true

require_relative '../../../lib/flame/errors/config_file_not_found_error'

describe 'Flame::Errors' do
	describe Flame::Errors::ConfigFileNotFoundError do
		subject(:error) { described_class.new(file_name, directory) }

		let(:file_name) { 'foo.y{a,}ml' }

		let(:correct_message) do
			"Config file 'foo.y{a,}ml' not found in 'config/'"
		end

		context 'directory without slashes at start and at end' do
			let(:directory) { 'config' }

			it_behaves_like 'error with correct output'
		end

		context 'directory without slash at start and with slash at end' do
			let(:directory) { 'config/' }

			it_behaves_like 'error with correct output'
		end

		context 'directory with slash at start and without slash at end' do
			let(:directory) { '/config' }

			it_behaves_like 'error with correct output'
		end

		context 'directory with slashes at start and at end' do
			let(:directory) { '/config/' }

			it_behaves_like 'error with correct output'
		end
	end
end
