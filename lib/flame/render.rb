require 'tilt'
require 'tilt/plain'
require 'tilt/erb'

module Flame
	## Helper for render functionality
	class Render
		def initialize(ctrl, path, options = {})
			## Take options for rendering
			@ctrl = ctrl
			@scope = options.delete(:scope) || @ctrl
			@layout = options.delete(:layout) || 'layout.*'
			## And get the rest variables to locals
			@locals = options.merge(options.delete(:locals) || {})
			## Find filename
			@filename = find_file(path)
			@layout = nil if File.basename(@filename)[0] == '_'
			## Compile Tilt to instance hash
			tilts[@filename] ||= Tilt.new(@filename)
		end

		def render
			## Render Tilt from instance hash with new options
			layout_render tilts[@filename].render(@scope, @locals)
		end

	private

		def self.tilts
			@tilts ||= {}
		end

		def tilts
			self.class.tilts
		end

		using GorillaPatch::StringExt

		## TODO: Add `views_dir` for Application and Controller
		## TODO: Add `layout` method for Controller
		def find_file(path)
			## Get full filename
			Dir[File.join(
				@ctrl.config[:views_dir],
				"{#{controller_dirs.join(',')},}",
				"#{path}.*"
			)].find do |file|
				Tilt[file]
			end
		end

		def controller_dirs
			## Build controller_dirs
			controller_dir = (
				@ctrl.class.name.underscore.split('_') - %w(controller ctrl)
			).join('_')
			[controller_dir, controller_dir.split('/').last]
		end

		def layout_render(result)
			layout_filename = find_file(@layout)
			## Compile layout to hash
			return result unless layout_filename
			tilts[layout_filename] ||= Tilt.new(layout_filename)
			return result unless tilts[layout_filename]
			tilts[layout_filename].render(@scope, @locals) { result }
		end
	end
end
