# frozen_string_literal: true

require_relative 'lib/flame/version'

Gem::Specification.new do |s|
	s.name        = 'flame'
	s.version     = Flame::VERSION

	s.summary     = 'Web-framework, based on MVC-pattern'
	s.description = <<~DESC
		Use controller's classes with instance methods as routing actions,
		mounting its in application class.
	DESC

	s.authors     = ['Alexander Popov']
	s.email       = ['alex.wayfer@gmail.com']
	s.license     = 'MIT'

	s.metadata = {
		'bug_tracker_uri' => 'https://github.com/AlexWayfer/flame/issues',
		'documentation_uri' =>
			"http://www.rubydoc.info/gems/flame/#{Flame::VERSION}",
		'source_code_uri' => 'https://github.com/AlexWayfer/flame',
		'wiki_uri' => 'https://github.com/AlexWayfer/flame/wiki'
	}

	s.metadata['homepage_uri'] = s.metadata['source_code_uri']
	s.homepage = s.metadata['homepage_uri']

	s.required_ruby_version = '>= 2.5'

	s.add_runtime_dependency 'addressable', '~> 2.5'
	s.add_runtime_dependency 'gorilla_patch', '>= 3.0', '< 5'
	s.add_runtime_dependency 'memery', '~> 1.0'
	s.add_runtime_dependency 'rack', '~> 2.1'
	s.add_runtime_dependency 'tilt', '~> 2.0'

	s.add_development_dependency 'codecov', '~> 0.1.14'
	s.add_development_dependency 'pry-byebug', '~> 3.5'
	s.add_development_dependency 'rack-test', '~> 1.1'
	s.add_development_dependency 'rake', '~> 13.0'
	s.add_development_dependency 'rspec', '~> 3.7'
	s.add_development_dependency 'rubocop', '~> 0.88.0'
	s.add_development_dependency 'rubocop-performance', '~> 1.5'
	s.add_development_dependency 'rubocop-rspec', '~> 1.38'
	s.add_development_dependency 'simplecov', '~> 0.18.0'

	s.files = Dir['{lib,public}/**/{*,.*}']
end
