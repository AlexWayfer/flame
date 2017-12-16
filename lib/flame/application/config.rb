# frozen_string_literal: true

module Flame
	class Application
		## Class for Flame::Application.config
		class Config < Hash
			## Create an instance of application config
			## @param app [Flame::Application] application
			## @param hash [Hash] config content
			def initialize(app, hash = {})
				@app = app
				replace(hash)
			end

			## Get config value by key
			## @param key [Symbol] config key
			## @return [Object] config value
			def [](key)
				result = super(key)
				if result.class <= Proc && result.parameters.empty?
					result = @app.class_exec(&result)
				end
				result
			end

			## Method for loading YAML-files from config directory
			## @param file [String, Symbol] file name (typecast to String with '.yml')
			## @param key [Symbol, String, nil]
			##   key for allocating YAML in config Hash (typecast to Symbol)
			## @param set [Boolean] allocating YAML in Config Hash
			## @example Load SMTP file from `config/smtp.yml' to config[]
			##   config.load_yaml('smtp.yml')
			## @example Load SMTP file without extension, by Symbol
			##   config.load_yaml(:smtp)
			## @example Load SMTP file with other key to config[:mail]
			##   config.load_yaml('smtp.yml', key: :mail)
			## @example Load SMTP file without allocating in config[]
			##   config.load_yaml('smtp.yml', set: false)
			def load_yaml(file, key: nil, set: true)
				file = "#{file}.yml" if file.is_a? Symbol
				file_path = File.join(self[:config_dir], file)
				yaml = YAML.load_file(file_path)
				key ||= File.basename(file, '.*')
				self[key.to_sym] = yaml if set
				yaml
			end
		end
	end
end
