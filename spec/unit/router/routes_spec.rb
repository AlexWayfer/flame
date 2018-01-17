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

		it 'should works for HTTP-methods as Symbol keys' do
			routes = @init.call('/foo/bar')
			routes['foo']['bar'][:GET] = 42
			routes['foo']['bar'][:GET].should.equal 42
		end
	end

	describe '#navigate' do
		describe 'for path without arguments' do
			should 'works with Path Part argument' do
				path = Flame::Path.new('/foo/bar')
				@routes.navigate(*path.parts).should.equal('baz' => {})
			end

			should 'works with String argument' do
				@routes.navigate('foo', 'bar').should.equal('baz' => {})
			end
		end

		describe 'for path with arguments' do
			let(:routes) { @init.call('/:first/:second') }

			should 'works with Path Part argument' do
				path = Flame::Path.new('/foo')
				routes.navigate(*path.parts).should.equal(':second' => {})
			end

			should 'works with String argument' do
				routes.navigate('foo').should.equal(':second' => {})
			end
		end

		describe 'for path with optional argument at beginning' do
			let(:routes) { @init.call('/:?first/second/third') }

			should 'works with Path Part argument' do
				path = Flame::Path.new('/second')
				routes.navigate(*path.parts).should.equal('third' => {})
			end

			should 'works with String argument' do
				routes.navigate('second').should.equal('third' => {})
			end
		end

		should 'works for root path' do
			@routes.navigate('/').should.equal('foo' => { 'bar' => { 'baz' => {} } })
		end

		should 'return nested routes from path' do
			routes = @init.call(['/foo', '/:?var', '/bar'])
			routes.navigate('/foo').should.equal routes['foo'][':?var']
			routes.navigate('/foo/some').should.equal routes['foo'][':?var']
			routes.navigate('/foo/some/bar')
				.should.equal routes['foo'][':?var']['bar']
		end

		should 'return nil for not-existing path' do
			@routes.navigate('/foo/baz').should.be.nil
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
end
