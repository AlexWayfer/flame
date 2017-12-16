# frozen_string_literal: true

module Flame
	module Errors
		## Error for not found template file in Render
		class TemplateNotFoundError < StandardError
			## Create a new instance of error
			## @param controller [Flame::Controller]
			##   controller from which template not found
			## @param path [String, Symbol] path of not founded template
			def initialize(controller, path)
				@controller = controller
				@controller = @controller.class unless @controller.is_a? Class
				@path = path
			end

			## Calculated message of the error
			## @return [String] message of the error
			def message
				"Template '#{@path}' not found for '#{@controller}'"
			end
		end
	end
end
