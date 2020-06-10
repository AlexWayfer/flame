# frozen_string_literal: true

require_relative 'errors/config_file_not_found_error'

module Flame
	## Class for application configuration
	class Config < Hash
		DEFAULT_DIRS =
			%i[public views config tmp].each_with_object({}) do |key, result|
				result[:"#{key}_dir"] = proc { File.join(self[:root_dir], key.to_s) }
			end.freeze

		## Create an instance of application config
		## @param app [Flame::Application] application
		## @param hash [Hash] config content
		def initialize(root_dir)
			replace DEFAULT_DIRS.merge(
				root_dir: File.realpath(root_dir),
				environment: ENV['RACK_ENV'] || 'development'
			)
		end

		## Get config value by key
		## @param key [Symbol] config key
		## @return [Object] config value
		def [](key)
			result = super(key)
			result = instance_exec(&result) if result.class <= Proc && result.parameters.empty?
			result
		end

		## Method for loading YAML-files from config directory
		## @param file [String, Symbol]
		##   file name (typecast to String with '.yaml')
		## @param key [Symbol, String, nil]
		##   key for allocating YAML in config Hash (typecast to Symbol)
		## @param set [Boolean] allocating YAML in Config Hash
		## @example Load SMTP file from `config/smtp.yaml' to config[]
		##   config.load_yaml('smtp.yaml')
		## @example Load SMTP file without extension, by Symbol
		##   config.load_yaml(:smtp)
		## @example Load SMTP file with other key to config[:mail]
		##   config.load_yaml('smtp.yaml', key: :mail)
		## @example Load SMTP file without allocating in config[]
		##   config.load_yaml('smtp.yaml', set: false)
		def load_yaml(file, key: nil, set: true)
			file = "#{file}.y{a,}ml" if file.is_a? Symbol
			file_path = find_config_file file

			yaml = YAML.load_file(file_path)
			key ||= File.basename(file, '.*')
			self[key.to_sym] = yaml if set
			yaml
		end

		private

		def find_config_file(filename)
			file_path = Dir[File.join(self[:config_dir], filename)].first
			return file_path if file_path

			raise Errors::ConfigFileNotFoundError.new(
				filename, self[:config_dir].sub(self[:root_dir], '')
			)
		end
	end
end
