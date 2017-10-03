# frozen_string_literal: true

require 'pathname'

require 'tilt'
require 'tilt/plain'
require 'tilt/erb'

require 'gorilla-patch/inflections'

require_relative 'errors/template_not_found_error'

module Flame
	## Helper for render functionality
	class Render
		def initialize(controller, path, options = {})
			## Take options for rendering
			@controller = controller
			@scope = options.delete(:scope) { @controller }
			@layout = options.delete(:layout) { 'layout.*' }
			## Options for Tilt Template
			@tilt_options = options.delete(:tilt)
			## And get the rest variables to locals
			@locals = options.merge(options.delete(:locals) { {} })
			## Find filename
			@filename = find_file(path)
			unless @filename
				raise Flame::Errors::TemplateNotFoundError.new(controller, path)
			end
			@layout = nil if File.basename(@filename)[0] == '_'
		end

		## Render template
		## @param cache [Boolean] cache compiles or not
		def render(cache: true)
			@cache = cache
			## Compile Tilt to instance hash
			return unless @filename
			tilt = compile_file
			## Render Tilt from instance hash with new options
			layout_render tilt.render(@scope, @locals)
		end

		private

		def views_dir
			@controller.config[:views_dir]
		end

		## Compile file with Tilt engine
		## @param filename [String] filename
		def compile_file(filename = @filename)
			cached = @controller.cached_tilts[filename]
			return cached if @cache && cached
			compiled = Tilt.new(filename, nil, @tilt_options)
			@controller.cached_tilts[filename] ||= compiled if @cache
			compiled
		end

		## @todo Add `views_dir` for Application and Controller
		## @todo Add `layout` method for Controller

		## Common method for `find_file` and `find_layouts`
		def find_files(path, dirs)
			paths = [path]
			paths.push(dirs.last) if path.to_sym == :index
			dirs.push(nil)
			files = Dir[
				File.join(views_dir, "{#{dirs.join(',')}}", "{#{paths.join(',')}}.*")
			]
			clean_paths files
		end

		def clean_paths(paths)
			paths.map! { |path| Pathname.new(path).cleanpath.to_s }.uniq
		end

		## Find template-file by path
		def find_file(path)
			find_files(path, controller_dirs).find { |file| Tilt[file] }
		end

		## Find layout-files by path
		def find_layouts(path)
			find_files(path, layout_dirs)
				.select { |file| Tilt[file] }
				.sort! { |a, b| b.split('/').size <=> a.split('/').size }
		end

		using GorillaPatch::Inflections

		## Find possible directories for the controller
		def controller_dirs
			parts = @controller.class.underscore.split('/').map do |part|
				%w[_controller _ctrl]
					.find { |suffix| part.chomp! suffix }
				part
				## Alternative, but slower by ~50%:
				# part.sub(/_(controller|ctrl)$/, '')
			end
			combine_parts(parts).map! { |path| path.join('/') }
		end

		## Make combinations in order with different sizes
		## @example Make parts for ['project', 'namespace', 'controller']
		##   # => [
		##          ['project', 'namespace', 'controller'],
		##          ['project', 'namespace'],
		##          ['namespace', 'controller'],
		##          ['namespace']
		##        ]
		def combine_parts(parts)
			parts.size.downto(1).with_object([]) do |i, arr|
				arr.push(*parts.combination(i).to_a)
			end
			# variants.uniq!.reject!(&:empty?)
		end

		def layout_dirs
			file_dir = Pathname.new(@filename).dirname
			diff_path = file_dir.relative_path_from Pathname.new(views_dir)
			diff_parts = diff_path.to_s.split('/')
			diff_parts.map.with_index do |_part, ind|
				diff_parts[0..-(ind + 1)].join('/')
			end
		end

		## Render the layout with template
		## @param result [String] result of template rendering
		def layout_render(content)
			return content unless @layout
			layout_files = find_layouts(@layout)
			return content if layout_files.empty?
			layout_files.each_with_object(content.dup) do |layout_file, result|
				layout = compile_file(layout_file)
				result.replace layout.render(@scope, @locals) { result }
			end
		end
	end
end
