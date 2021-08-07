# frozen_string_literal: true

require_relative 'lib/flame/version'

Gem::Specification.new do |spec|
	spec.name        = 'flame'
	spec.version     = Flame::VERSION

	spec.summary     = 'Web-framework, based on MVC-pattern'
	spec.description = <<~DESC
		Use controller's classes with instance methods as routing actions,
		mounting its in application class.
	DESC

	spec.authors     = ['Alexander Popov']
	spec.email       = ['alex.wayfer@gmail.com']
	spec.license     = 'MIT'

	github_uri = "https://github.com/AlexWayfer/#{spec.name}"

	spec.homepage = github_uri

	spec.metadata = {
		'bug_tracker_uri' => "#{github_uri}/issues",
		'changelog_uri' => "#{github_uri}/blob/v#{spec.version}/CHANGELOG.md",
		'documentation_uri' => "http://www.rubydoc.info/gems/#{spec.name}/#{spec.version}",
		'homepage_uri' => spec.homepage,
		'source_code_uri' => github_uri,
		'wiki_uri' => "#{github_uri}/wiki"
	}

	spec.files = Dir['lib/**/*.rb', 'public/**/*.ico', 'README.md', 'LICENSE.txt', 'CHANGELOG.md']

	spec.required_ruby_version = '>= 2.5', '< 4'

	spec.add_runtime_dependency 'addressable', '~> 2.5'
	spec.add_runtime_dependency 'alt_memery', '~> 2.0'
	spec.add_runtime_dependency 'gorilla_patch', '>= 3.0', '< 5'
	spec.add_runtime_dependency 'rack', '~> 2.1'
	spec.add_runtime_dependency 'tilt', '~> 2.0'

	spec.add_development_dependency 'pry-byebug', '~> 3.9'

	spec.add_development_dependency 'bundler', '~> 2.0'
	spec.add_development_dependency 'bundler-audit', '~> 0.8.0'
	spec.add_development_dependency 'gem_toys', '~> 0.8.0'
	spec.add_development_dependency 'toys', '~> 0.12.0'

	spec.add_development_dependency 'better_errors', '~> 2.0'
	spec.add_development_dependency 'codecov', '~> 0.5.1'
	spec.add_development_dependency 'rack-test', '~> 1.1'
	spec.add_development_dependency 'rspec', '~> 3.9'
	spec.add_development_dependency 'simplecov', '~> 0.21.2'

	spec.add_development_dependency 'rubocop', '~> 1.3'
	spec.add_development_dependency 'rubocop-performance', '~> 1.0'
	spec.add_development_dependency 'rubocop-rspec', '~> 2.0'
end
