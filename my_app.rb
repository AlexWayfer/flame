## Test app for Framework
class MyApp < Atom::Nucleus
	puts '-- Init MyApp'

	route :hello do
		p ':hello'
		"Hello #{params['name'] || 'World'}!"
	end

	route '/hello/:name' do |name|
		p '/hello/:name'
		"Hello, #{name}"
	end

	route '/goodbye' do
		status 500
		'Goodbye Cruel World!'
	end
end
