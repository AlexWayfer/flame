# frozen_string_literal: true

module Flame
	module Errors
		## Error for not found config file in Config
		class ConfigFileNotFoundError < StandardError
			## Create a new instance of error
			## @param file_name [String]
			##   file name mask by which file was not found
			## @param directory [String] directory in which file was not found
			def initialize(file_name, directory)
				directory = directory.sub(%r{^/+}, '').sub(%r{/+$}, '')
				super "Config file '#{file_name}' not found in '#{directory}/'"
			end
		end
	end
end
