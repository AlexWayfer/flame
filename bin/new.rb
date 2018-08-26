# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require 'gorilla_patch/inflections'
require 'erb'

require_relative 'new/app'

module FlameCLI
	## Command for generating new objects
	class New < Thor
		desc(
			'app APP_NAME',
			'Generate new application directory with sub-directories'
		)
		def app(app_name)
			self.class::App.new app_name
		end
	end
end
