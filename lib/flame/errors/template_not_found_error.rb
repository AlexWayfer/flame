# frozen_string_literal: true

module Flame
	module Errors
		## Error for not found template file in Render
		class TemplateNotFoundError < StandardError
			def initialize(controller, path)
				@controller = controller
				@controller = @controller.class unless @controller.is_a? Class
				@path = path
			end

			def message
				"Template '#{@path}' not found for '#{@controller}'"
			end
		end
	end
end
