# frozen_string_literal: true

describe Flame::Dispatcher::Response do
	subject(:response) { Flame::Dispatcher::Response.new }

	it { is_expected.to be_kind_of Rack::Response }

	describe '#content_type=' do
		before do
			response.content_type = content_type
		end

		subject { response.content_type }

		context 'MIME-type' do
			let(:content_type) { 'text/html' }

			it { is_expected.to eq 'text/html' }
		end

		context 'file extension' do
			let(:content_type) { '.css' }

			it { is_expected.to eq 'text/css' }
		end
	end
end
