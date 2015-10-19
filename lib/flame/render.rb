require 'tilt'
require 'tilt/plain'
require 'tilt/erb'

module Flame
	## Helper for render functionality
	module Render
		def view(path, options = {})
			## Take options for rendering
			scope = options.delete(:scope) || self
			layout = options.delete(:layout) || 'layout.*'
			## And get the rest variables to locals
			locals = options.merge(options.delete(:locals) || {})
			## Find filename
			filename = find_file(path)
			## Compile Tilt to instance hash
			@tilts ||= {}
			@tilts[filename] ||= Tilt.new(filename)
			## Render Tilt from instance hash with new options
			layout_render layout, @tilts[filename].render(scope, locals)
		end

		alias_method :render, :view

	private

		using GorillaPatch::StringExt

		## TODO: Add `views_dir` for Application and Controller
		## TODO: Add `layout` method for Controller
		def find_file(path)
			## Get full filename
			Dir[File.join(
				config[:views_dir],
				"{#{controller_dirs.join(',')},}",
				"#{path}.*"
			)].find do |file|
				Tilt[file]
			end
		end

		def controller_dirs
			## Build controller_dirs
			controller_dir = (
				self.class.name.underscore.split('_') - %w(controller ctrl)
			).join('_')
			[controller_dir, controller_dir.split('/').last]
		end

		def layout_render(layout, result)
			layout_filename = find_file(layout)
			## Compile layout to hash
			return result unless layout_filename
			@tilts[layout_filename] ||= Tilt.new(layout_filename)
			return result unless @tilts[layout_filename]
			@tilts[layout_filename].render { result }
		end
	end
end
