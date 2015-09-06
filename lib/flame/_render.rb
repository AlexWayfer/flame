require 'tilt'

module Flame
	## Helper for render functionality
	module Render
		def view(path, options = {})
			## Take options for rendering
			scope = options.delete(:scope) || self
			## And get the rest variables to locals
			locals = options.merge(options.delete(:locals) || {})
			## Find filename
			filename = find_file(path)
			## Compile Tilt to instance hash
			@tilts ||= {}
			@tilts[filename] ||= Tilt.new(filename)
			## Render Tilt from instance hash with new options
			@tilts[filename].render(scope, locals)
		end

		alias_method :render, :view

	private

		def find_file(path)
			## Build controller_dir
			controller_dir = (
				self.class.name.split(/(?=[A-Z])/) - ['Controller']
			).join('_').downcase
			## Get full filename
			Dir[File.join(
				config[:views_dir],
				"{#{controller_dir},}",
				"#{path}.*"
			)].find do |file|
				Tilt[file]
			end
		end
	end
end
