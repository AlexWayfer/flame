# frozen_string_literal: true

## Test app for Framework
class App < Flame::Application
	mount :home

	mount :users
end
