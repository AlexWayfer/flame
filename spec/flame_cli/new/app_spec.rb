# frozen_string_literal: true

require 'net/http'

describe 'FlameCLI::New::App' do
	app_name = 'foo_bar'

	execute_command = proc do
		`#{FLAME_CLI} new app #{app_name}`
	end

	template_dir = File.join(__dir__, '..', '..', '..', 'template')
	template_dir_pathname = Pathname.new(template_dir)
	template_ext = '.erb'

	after do
		FileUtils.rm_r File.join(__dir__, '..', '..', '..', app_name)
	end

	it 'should print correct output' do
		execute_command.call
			.should match_words(
				"Creating '#{app_name}' directory...",
				'Copy template directories and files...',
				'Clean directories...',
				'Replace module names in template...',
				'- config.ru',
				'- app.rb',
				'- Rakefile',
				'- config/config.rb',
				'- config/sequel.rb',
				'- controllers/_controller.rb',
				'- controllers/site/_controller.rb',
				'- controllers/site/index_controller.rb',
				'Done!'
			)
	end

	it 'should create root directory with received app name' do
		execute_command.call
		Dir.exist?(app_name).should.be.true
	end

	it 'should copy template directories and files into app root directory' do
		execute_command.call
		Dir[File.join(template_dir, '**', '*')].each do |filename|
			filename_pathname = Pathname.new(filename)
				.relative_path_from(template_dir_pathname)
			next if File.dirname(filename).split(File::SEPARATOR).include? 'views'
			if filename_pathname.extname == template_ext
				filename_pathname = filename_pathname.sub_ext('')
			end
			app_filename = File.join(app_name, filename_pathname)
			File.exist?(app_filename).should.be.true
		end
	end

	it 'should clean directories' do
		execute_command.call
		Dir[File.join(app_name, '**', '.keep')].should.be.empty
	end

	it 'should render app name in files' do
		read_file = ->(*path_parts) { File.read File.join(app_name, *path_parts) }
		execute_command.call
		read_file.call('config.ru').should match_words(
			'use Rack::Session::Cookie, FB::Application.config[:session][:cookie]',
			'File.join __dir__, FB::Application.config[:server][:logs_dir]',
			'FB::Application.config[:logger] = Logger.new',
			'FB::DB.loggers <<',
			'FB.logger',
			'FB::DB.freeze',
			'run FB::Application'
		)
		read_file.call('app.rb').should match_words(
			'module FooBar',
			'include FB::Config'
		)
		read_file.call('Rakefile').should match_words(
			'FooBar::DB.loggers << Logger.new($stdout)',
			'DB = FooBar::DB'
		)
		read_file.call('controllers', '_controller.rb').should match_words(
			'module FooBar',
			'FB.logger'
		)
		read_file.call('controllers', 'site', '_controller.rb').should match_words(
			'module FooBar',
			'class Controller < FB::Controller'
		)
		read_file.call('controllers', 'site', 'index_controller.rb')
			.should match_words(
				'module FooBar',
				'class IndexController < FB::Site::Controller'
			)
		read_file.call('config', 'config.rb').should match_words(
			'module FooBar',
			"SITE_NAME = 'FooBar'",
			"ORGANIZATION_NAME = 'FooBar LLC'",
			'::FB = ::FooBar',
			'FB::Application.config[:logger]'
		)
		read_file.call('config', 'sequel.rb').should match_words(
			'module FooBar'
		)
	end

	should 'generate working app' do
		execute_command.call
		Dir.chdir app_name
		## HACK for newest unpublished features
		File.write(
			'Gemfile',
			File.read('Gemfile').sub("gem 'flame'\n", "gem 'flame', path: '..'\n")
		)
		%w[server].each do |config|
			FileUtils.cp "config/#{config}.example.yml", "config/#{config}.yml"
		end
		`bundle install --gemfile=./Gemfile`
		pid = spawn './server start'
		sleep 3
		uri = URI('http://localhost:3000/')
		Net::HTTP.get(uri).should.equal "<h1>Hello, world!</h1>\n"
		`./server stop`
		Process.wait pid
		Dir.chdir '..'
	end
end
