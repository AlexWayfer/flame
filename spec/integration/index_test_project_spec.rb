# frozen_string_literal: true

module IndexTestProject
	## Example of index controller
	class IndexController < Flame::Controller
		def index
			'This is index'
		end
	end

	## Mount example controller to app
	class Application < Flame::Application
		mount :index, '/'
	end
end

describe IndexTestProject do
	include Rack::Test::Methods

	let(:app) do
		IndexTestProject::Application.new
	end

	describe 'index' do
		before { get '/' }

		describe 'last_response' do
			subject { last_response }

			it { is_expected.to be_ok }

			describe 'body' do
				subject { super().body }

				it { is_expected.to eq 'This is index' }
			end
		end
	end

	describe 'default 404' do
		before { get '/404' }

		describe 'last_response' do
			subject { last_response }

			it { is_expected.to be_not_found }

			describe 'body' do
				subject { super().body }

				it { is_expected.to eq 'Not Found' }
			end
		end
	end
end
