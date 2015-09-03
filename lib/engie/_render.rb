require 'tilt'

module Engie
	## Helper for render functionality
	module Render
		def view(path, options = {})
			## Take options for rendering
			scope = options.delete(:scope) || self
			## And get the rest variables to locals
			locals = options.merge(options.delete(:locals) || {})
			## Get full filename
			filename = Dir[
				File.join(config[:views_dir], "#{path}.*")
			].find do |file|
				Tilt[file]
			end
			## Compile Tilt to instance hash
			@tilts ||= {}
			@tilts[filename] ||= Tilt.new(filename)
			## Render Tilt from instance hash with new options
			@tilts[filename].render(scope, locals)
		end
	end
end
