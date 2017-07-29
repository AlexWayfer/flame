# frozen_string_literal: true

require_relative '../path'
require_relative '../validators'

module Flame
	class Router
		## Class for Route in Router.routes
		class Route
			attr_reader :controller, :action

			## @param controller [Flame::Controller] controller
			## @param action [Symbol] action
			def initialize(controller, action)
				@controller = controller
				@action = action
			end

			## Method for Routes comparison
			## @param other [Flame::Router::Route] other route
			## @return [true, false] equal or not
			def ==(other)
				return false unless other.is_a? self.class
				%i[controller action].reduce(true) do |result, method|
					result && (
						public_send(method) == other.public_send(method)
					)
				end
			end
		end
	end
end
