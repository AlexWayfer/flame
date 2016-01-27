require 'tilt'
require 'tilt/plain'
require 'tilt/erb'

require 'gorilla-patch/string'

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
			@ctrl.instance_exec { halt 404 } unless @filename
			@layout = nil if File.basename(@filename)[0] == '_'
		end

		def render(cache: true)
			## Compile Tilt to instance hash
			tilt = cache ? self.class.tilts[@filename] ||= compile : compile
			## Render Tilt from instance hash with new options
			layout_render tilt.render(@scope, @locals), cache: cache
		end

		private

		class << self
			private

			def tilts
				@tilts ||= {}
			end
		end

		using GorillaPatch::StringExt

		def compile(filename = @filename)
			Tilt.new(filename)
		end

		## TODO: Add `views_dir` for Application and Controller
		## TODO: Add `layout` method for Controller
		def find_file(path)
			## Get full filename
			Dir[File.join(
				@ctrl.config[:views_dir],
				"{#{controller_dirs.join(',')},}",
				"#{path}.*"
			)].uniq.find do |file|
				Tilt[file]
			end
		end

		def controller_dirs
			## Build controller_dirs
			controller_dir = (
				@ctrl.class.name.underscore.split('_') - %w(controller ctrl)
			).join('_')
			controller_dir_parts = controller_dir.split('/')
			[controller_dir,
			 controller_dir_parts[1..-1].join('/'),
			 controller_dir_parts[1..-2].join('/'),
			 controller_dir_parts.last]
		end

		def layout_render(result, cache: true)
			layout_file = find_file(@layout)
			## Compile layout to hash
			return result unless layout_file
			layout =
					if cache
						self.class.tilts[layout_file] ||= compile(layout_file)
					else
						compile(layout_file)
					end
			return result unless layout
			layout.render(@scope, @locals) { result }
		end
	end
end
