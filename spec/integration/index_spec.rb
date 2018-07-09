# frozen_string_literal: true

require_relative 'app'

## Example of index controller
class IndexController < Flame::Controller
	def index
		'This is index'
	end
end

## Mount example controller to app
class IntegrationApp
	mount :index, '/'
end

describe IndexController do
	include Rack::Test::Methods

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

				it { is_expected.to eq '<h1>Not Found</h1>' }
			end
		end
	end
end
