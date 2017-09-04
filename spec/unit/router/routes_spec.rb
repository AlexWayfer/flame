# frozen_string_literal: true

describe Flame::Router::Routes do
	before do
		@init = lambda do |path = '/foo/bar/baz'|
			Flame::Router::Routes.new(path)
		end
		@routes = @init.call
	end

	it 'should be a kind of Hash' do
		@routes.should.be.kind_of Hash
	end

	describe '#initialize' do
		it 'should receive Flame::Path for building' do
			path = Flame::Path.new('/foo/bar/baz')
			@init.call(path)
				.should.equal('foo' => { 'bar' => { 'baz' => {} } })
		end

		it 'should receive path as String for building' do
			@init.call('/foo/bar/baz')
				.should.equal('foo' => { 'bar' => { 'baz' => {} } })
		end

		it 'should build nested Hashes as kind of Routes' do
			deep_check = lambda do |values|
				values.all? do |value|
					value.is_a?(Flame::Router::Routes) &&
						(deep_check.call(value.values) || value.values.empty?)
				end
			end

			deep_check.call(@routes.values).should.be.true
		end
	end

	describe '#[]' do
		it 'should works with Path Part for key which is not argument' do
			path_part = Flame::Path::Part.new('foo')
			@routes[path_part].should.equal('bar' => { 'baz' => {} })
		end

		it 'should works with String for key which is not argument ' do
			@routes['foo'].should.equal('bar' => { 'baz' => {} })
		end

		it 'should works with Path Part for key which is argument' do
			path_part = Flame::Path::Part.new('value')
			routes = @init.call('/:first/:second')
			routes[path_part].should.equal(':second' => {})
		end

		it 'should works with String for key which is argument' do
			routes = @init.call('/:first/:second')
			routes['value'].should.equal(':second' => {})
		end

		it 'should works for HTTP-methods as Symbol keys' do
			routes = @init.call('/foo/bar')
			routes['foo']['bar'][:GET] = 42
			routes['foo']['bar'][:GET].should.equal 42
		end
	end

	describe '#dig' do
		it 'should works with Path Part for Path Parts which are not arguments' do
			path = Flame::Path.new('/foo/bar')
			@routes.dig(*path.parts).should.equal('baz' => {})
		end

		it 'should works with String for Path Parts which are not arguments' do
			@routes.dig('foo', 'bar').should.equal('baz' => {})
		end

		it 'should works with Path Part for Path Parts which are arguments' do
			path = Flame::Path.new('/foo/bar')
			routes = @init.call('/:first/:second/:?third')
			routes.dig(*path.parts).should.equal(':?third' => {})
		end

		it 'should works with String for Path Parts which are arguments' do
			routes = @init.call('/:first/:second/:?third')
			routes.dig('foo', 'bar').should.equal(':?third' => {})
		end

		should 'works for root path' do
			@routes.dig('/').should.equal('foo' => { 'bar' => { 'baz' => {} } })
		end
	end

	describe '#allow' do
		should 'return correct String for multiple allow HTTP-methods' do
			routes = @init.call('/foo/bar')
			routes['foo']['bar'][:GET]  = 42
			routes['foo']['bar'][:POST] = 84
			routes['foo']['bar'].allow.should.equal 'GET, POST, OPTIONS'
		end

		should 'return nil for not-existing path' do
			@routes['foo']['bar'].allow.should.be.nil
		end
	end

	describe '#endpoint' do
		should 'return nested routes from path' do
			routes = @init.call(['/foo', '/:?var', '/bar'])
			routes.endpoint('/foo').should.equal routes['foo'][':?var']
			routes.endpoint('/foo/some').should.equal routes['foo'][':?var']
			routes.endpoint('/foo/some/bar')
				.should.equal routes['foo'][':?var']['bar']
		end

		should 'return nil for not-existing path' do
			@routes.endpoint('/foo/baz').should.be.nil
		end
	end
end
