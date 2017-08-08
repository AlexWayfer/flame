# frozen_string_literal: true

module FlameCLI
	class New < Thor
		## Class for Flame Application
		class App
			using GorillaPatch::Inflections

			def initialize(app_name)
				@app_name = app_name
				@module_name = @app_name.camelize
				@short_module_name = @module_name
					.split(/([[:upper:]][[:lower:]]*)/).map! { |s| s[0] }.join

				make_dir do
					copy_template
				end

				puts 'Done!'
				system "cd #{@app_name}"
			end

			private

			def make_dir(&block)
				puts "Creating '#{@app_name}' directory..."
				FileUtils.mkdir @app_name
				FileUtils.cd @app_name, &block
			end

			def copy_template
				puts 'Copy template directories and files...'
				FileUtils.cp_r File.join(__dir__, '..', '..', 'template', '.'), '.'
				clean_dirs
				render_templates
			end

			def clean_dirs
				puts 'Clean directories...'
				FileUtils.rm Dir[File.join('**', '*', '.keep')]
			end

			def render_templates
				puts 'Replace module names in template...'
				Dir[File.join('**', '*.erb')].each do |file|
					## Skip views
					next if File.dirname(file).split(File::SEPARATOR).include? 'views'
					render_template_file file
				end
			end

			def render_template_file(file)
				file_pathname = Pathname.new(file)
				basename_pathname = file_pathname.sub_ext('')
				puts "- #{basename_pathname}"
				content = ERB.new(File.read(file)).result(binding)
				File.write(basename_pathname, content)
				FileUtils.rm file
			end
		end
	end
end
