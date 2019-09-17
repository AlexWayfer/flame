# frozen_string_literal: true

require_relative 'app'

## Example of CRUD controller
class CRUDController < Flame::Controller
	def index
		'List of items'
	end

	def create
		'Create item'
	end

	def show(id)
		"Show item #{id}"
	end

	def update(id)
		"Edit item #{id}"
	end

	def delete(id)
		"Delete item #{id}"
	end
end

class NestedCRUDController < Flame::Controller
	def create
		'Create nested item'
	end
end

## Mount example controller to app
class IntegrationApp
	mount :CRUD, '/crud'
	mount NestedCRUDController, '/crud/:item_id/nested'
end

describe 'CRUD Controller' do
	include Rack::Test::Methods

	describe 'list of items' do
		before { get '/crud' }

		describe 'last_response' do
			subject { last_response }

			it { is_expected.to be_ok }

			describe 'body' do
				subject { super().body }

				it { is_expected.to eq 'List of items' }
			end
		end
	end

	describe 'create item' do
		before { post '/crud' }

		describe 'last_response' do
			subject { last_response }

			it { is_expected.to be_ok }

			describe 'body' do
				subject { super().body }

				it { is_expected.to eq 'Create item' }
			end
		end
	end

	describe 'show item' do
		before { get '/crud/2' }

		describe 'last_response' do
			subject { last_response }

			it { is_expected.to be_ok }

			describe 'body' do
				subject { super().body }

				it { is_expected.to eq 'Show item 2' }
			end
		end
	end

	describe 'update item' do
		before { put '/crud/4' }

		describe 'last_response' do
			subject { last_response }

			it { is_expected.to be_ok }

			describe 'body' do
				subject { super().body }

				it { is_expected.to eq 'Edit item 4' }
			end
		end
	end

	describe 'delete item' do
		before { delete '/crud/8' }

		describe 'last_response' do
			subject { last_response }

			it { is_expected.to be_ok }

			describe 'body' do
				subject { super().body }

				it { is_expected.to eq 'Delete item 8' }
			end
		end
	end

	describe 'create nested item' do
		before { post '/crud/2/nested' }

		describe 'last_response' do
			subject { last_response }

			it { is_expected.to be_ok }

			describe 'body' do
				subject { super().body }

				it { is_expected.to eq 'Create nested item' }
			end
		end
	end
end
