# frozen_string_literal: true

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
				'- _base_controller.rb',
				'- Rakefile',
				'- sequel.rb',
				'- config.rb',
				'- app.rb',
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
			'run FooBar::Application'
		)
		read_file.call('app.rb').should match_words(
			'module FooBar'
		)
		read_file.call('Rakefile').should match_words(
			'	FooBar::DB,',
			'Sequel::Migrator.run(FooBar::DB, migrations_dir)',
			'Sequel::Seeder.apply(FooBar::DB, seeds_dir)',
			'	FooBar::DB.extension :schema_dumper',
			'dump = FooBar::DB.dump_schema_migration',
			'Sequel::Migrator.run(FooBar::DB, db_dir, target: 1)'
		)
		read_file.call('controllers', '_base_controller.rb').should match_words(
			'module FooBar'
		)
		read_file.call('config', 'config.rb').should match_words(
			'module FooBar',
			"SITE_NAME = 'FooBar'.freeze"
		)
		read_file.call('config', 'sequel.rb').should match_words(
			'module FooBar'
		)
	end
end
