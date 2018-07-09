# frozen_string_literal: true

begin
	require 'rspec/core/rake_task'

	RSpec::Core::RakeTask.new(:spec)

	task default: :spec
rescue LoadError
	puts 'No RSpec available'
end

task :release, %i[version] do |_t, args|
	version = args[:version]

	raise ArgumentError, 'No version provided' unless version

	## Write new version to version file
	version_file = File.join(__dir__, 'lib/flame/version.rb')
	File.write version_file, File.read(version_file).sub(/'.+'/, "'#{version}'")

	## Commit version update
	sh "git add #{version_file}"
	sh "git commit -m 'Update version to #{version}'"

	## Tag commit
	sh "git tag -a v#{version} -m 'Version #{version}'"

	## Push commit
	sh 'git push'

	## Push tags
	sh 'git push --tags'

	## Build new gem file
	gemspec_file = Dir[File.join(__dir__, '*.gemspec')].first
	sh "gem build #{gemspec_file}"

	## Push new gem file
	gem_file = Dir[File.join(__dir__, "*-#{version}.gem")].first
	sh "gem push #{gem_file}"
end
