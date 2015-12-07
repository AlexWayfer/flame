Gem::Specification.new do |s|
	s.name        = 'flame'
	s.version     = '3.3.2'
	s.date        = Date.today.to_s

	s.summary     = 'Web-framework, based on MVC-pattern'
	s.description = 'Use controller\'s classes with instance methods' \
	                ' as routing actions, mounting its in application class.'

	s.authors     = ['Alexander Popov']
	s.email       = ['alex.wayfer@gmail.com']
	s.homepage    = 'https://gitlab.com/AlexWayfer/flame'
	s.license     = 'MIT'

	s.add_runtime_dependency 'rack', '~> 1'
	s.add_runtime_dependency 'tilt', '> 1.4', '< 3'
	s.add_runtime_dependency 'gorilla-patch', '~> 0.0', '>= 0.0.6'

	s.files = Dir[File.join('{lib,public}', '**', '*')]
end
