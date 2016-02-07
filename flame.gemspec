require_relative 'lib/flame/version'

Gem::Specification.new do |s|
	s.name        = 'flame'
	s.version     = Flame::VERSION
	s.date        = Date.today.to_s

	s.summary     = 'Web-framework, based on MVC-pattern'
	s.description = 'Use controller\'s classes with instance methods' \
	                ' as routing actions, mounting its in application class.'

	s.authors     = ['Alexander Popov']
	s.email       = ['alex.wayfer@gmail.com']
	s.homepage    = 'https://github.com/AlexWayfer/flame'
	s.license     = 'MIT'

	s.add_runtime_dependency 'rack', '~> 1'
	s.add_runtime_dependency 'tilt', '>= 1.4', '< 3'
	s.add_runtime_dependency 'gorilla-patch', '~> 0.0', '>= 0.0.7'

	s.files = Dir[File.join('{lib,public}', '**', '*')]
end
