# frozen_string_literal: true

require_relative 'lib/flame/version'

Gem::Specification.new do |s|
	s.name        = 'flame'
	s.version     = Flame::VERSION

	s.summary     = 'Web-framework, based on MVC-pattern'
	s.description = 'Use controller\'s classes with instance methods' \
	                ' as routing actions, mounting its in application class.'

	s.authors     = ['Alexander Popov']
	s.email       = ['alex.wayfer@gmail.com']
	s.homepage    = 'https://github.com/AlexWayfer/flame'
	s.license     = 'MIT'

	s.add_runtime_dependency 'addressable', '~> 2.5'
	s.add_runtime_dependency 'gorilla-patch', '~> 2.7'
	s.add_runtime_dependency 'rack', '~> 2'
	s.add_runtime_dependency 'thor', '~> 0'
	s.add_runtime_dependency 'tilt', '>= 2.0', '< 3'

	s.add_development_dependency 'codecov', '~> 0'
	s.add_development_dependency 'minitest-bacon', '~> 1'
	s.add_development_dependency 'minitest-reporters', '~> 1'
	s.add_development_dependency 'pry', '~> 0'
	s.add_development_dependency 'pry-byebug', '~> 3.5'
	s.add_development_dependency 'puma', '~> 3.9'
	s.add_development_dependency 'rack-console', '~> 1'
	s.add_development_dependency 'rack-test', '~> 0'
	s.add_development_dependency 'rack-utf8_sanitizer', '~> 1.3'
	s.add_development_dependency 'rake', '~> 12'
	s.add_development_dependency 'rubocop', '0.51'
	s.add_development_dependency 'simplecov', '~> 0'

	s.files = Dir[File.join('{lib,public,template}', '**', '{*,.*}')]
	s.executables = ['flame']
end
