# frozen_string_literal: true

class PathController
	def foo; end

	def bar(first); end

	def baz(first, second, third = nil); end
end

describe Flame::Path do
	before do
		@init = proc { |*args| Flame::Path.new(*args) }
		@path = @init.call '/foo/:first/:second/:?third'
	end

	describe '.merge' do
		it 'should merge from Array of Strings' do
			Flame::Path.merge(%w[foo bar baz])
				.should.equal 'foo/bar/baz'
		end

		it 'should merge from multiple parts as Strings' do
			Flame::Path.merge('/foo/bar', '/baz/bat')
				.should.equal '/foo/bar/baz/bat'
		end

		it 'should merge from multiple parts as Flame::Path' do
			first_path = @init.call('/foo/bar')
			second_path = @init.call('/baz/bat')
			Flame::Path.merge(first_path, second_path)
				.should.equal '/foo/bar/baz/bat'
		end

		it 'should merge without extra slashes' do
			Flame::Path.merge('///foo/bar//', '//baz/bat///')
				.should.equal '/foo/bar/baz/bat/'
		end
	end

	describe '#initialize' do
		it 'should receive path as String' do
			path = '/foo/bar'
			@init.call(path).to_s.should.equal path
		end

		it 'should receive many path parts' do
			@init.call('/foo', '/bar', 'baz').to_s.should.equal '/foo/bar/baz'
		end

		describe 'with path as Flame::Path' do
			should 'works' do
				path = @init.call('/foo/bar')
				@init.call(path).to_s.should.equal path
			end

			should 'not return the same object' do
				path = @init.call('/foo/bar')
				@init.call(path).to_s.should.not.be.same_as path
			end
		end
	end

	describe '#parts' do
		it 'should return array of path parts' do
			@init.call('/foo/bar/baz').parts.should.equal %w[foo bar baz]
		end
	end

	describe '#freeze' do
		it 'should freeze path' do
			@path.to_s.should.be.frozen
		end

		it 'should freeze path parts' do
			@path.parts.each { |part| part.should.be.frozen }
			@path.parts.should.be.frozen
		end
	end

	describe '#+' do
		describe 'with Flame::Path argument' do
			before do
				@part = Flame::Path.new('/:?fourth')
			end

			should 'return new concatenated Flame::Path' do
				result = @path + @part
				expected = Flame::Path.new('/foo/:first/:second/:?third/:?fourth')
				result.should.equal expected
			end

			should 'return new instance of Flame::Path' do
				result = @path + @part
				result.should.be.kind_of Flame::Path
			end

			should 'not be the same as the first part' do
				result = @path + @part
				result.should.not.be.same_as @path
			end

			should 'not be the same as the second part' do
				result = @path + @part
				result.should.not.be.same_as @part
			end
		end

		describe 'with String argument' do
			before do
				@part = '/:?fourth'
			end

			should 'return new concatenated Flame::Path' do
				result = @path + @part
				expected = Flame::Path.new('/foo/:first/:second/:?third/:?fourth')
				result.should.equal expected
			end

			should 'return new instance of Flame::Path' do
				result = @path + @part
				result.should.be.kind_of Flame::Path
			end

			should 'not be the same as the first part' do
				result = @path + @part
				result.should.not.be.same_as @path
			end
		end
	end

	describe '#<=>' do
		it 'should return 1 for other route with less count of path parts' do
			(@path <=> @init.call('/bar/:first/:second'))
				.should.equal(1)
		end

		it 'should return -1 for other route with greater count of path parts' do
			(@init.call('/bar/:first/:second') <=> @path)
				.should.equal(-1)
		end

		it 'should return 0 for other route with equal count of path parts' do
			(@path <=> @init.call('/bar/:first/:second/:?third'))
				.should.equal(0)
		end

		it 'should return 1 for other route with arguments' do
			(@init.call('/route/export_cards') <=> @init.call('/route/:id'))
				.should.equal(1)
		end
	end

	describe '#==' do
		it 'should compare by parts' do
			(@path == @init.call('/foo/:first/:second/:?third'))
				.should.equal true
		end

		it 'should receive String' do
			(@path == '/foo/:first/:second/:?third')
				.should.equal true
		end
	end

	describe '#adapt' do
		before do
			@adapt_init = proc do |path: nil, action: :baz|
				Flame::Path.new(path).adapt(PathController, action).to_s
			end
		end

		it 'should complete path with action name and parameters' do
			@adapt_init.call
				.should.equal '/baz/:first/:second/:?third'
		end

		it 'should complete path with parameters' do
			@adapt_init.call(path: '/foo')
				.should.equal '/foo/:first/:second/:?third'
		end

		it 'should complete path with missing parameters' do
			@adapt_init.call(path: '/foo/:second')
				.should.equal '/foo/:second/:first/:?third'
		end

		it 'should complete path without ending slash' \
		   ' if action has no parameters' do
			@adapt_init.call(action: :foo)
				.should.equal '/foo'
		end

		it 'should complete path without ending slash' \
		   ' if initial path has all parameters' do
			path = '/baz/:first/:second/:?third'
			@adapt_init.call(path: path)
				.should.equal path
		end
	end

	describe '#extract_arguments' do
		it 'should return arguments from other path' do
			@path.extract_arguments(
				@init.call('/foo/bar/baz')
			).should.equal Hash[first: 'bar', second: 'baz']
		end

		it 'should return decoded arguments from other path' do
			@path.extract_arguments(
				@init.call('/foo/another%20bar/baz')
			).should.equal Hash[first: 'another bar', second: 'baz']
		end

		it 'should return arguments with spaces instead of `+` from other path' do
			@path.extract_arguments(
				@init.call('/foo/another+bar/baz')
			).should.equal Hash[first: 'another bar', second: 'baz']
		end

		should 'extract missing optional argument before static part as nil' do
			@init.call('/foo/:?bar/baz').extract_arguments(
				@init.call('/foo/baz')
			).should.equal Hash[bar: nil]
		end

		should 'not return optional argument for path with slash at the end' do
			@path.extract_arguments(
				@init.call('/foo/bar/baz//')
			).should.equal Hash[first: 'bar', second: 'baz']
		end
	end

	describe '#assign_arguments' do
		it 'should assign arguments' do
			@path.assign_arguments(
				first: 'bar',
				second: 'baz'
			).should.equal '/foo/bar/baz'
		end

		it 'should not assign arguments without one required' do
			-> { @path.assign_arguments(first: 'bar') }
				.should.raise(Flame::Errors::ArgumentNotAssignedError)
				.message.should match_words(':second', '/foo/:first/:second/:?third')
		end
	end

	describe '#to_s' do
		it 'should return full path as String' do
			@init.call('/foo', 'bar', '/baz').to_s.should.equal '/foo/bar/baz'
		end
	end

	describe '#to_str' do
		it 'should return full path as String' do
			@init.call('/foo', 'bar', '/baz').to_str.should.equal '/foo/bar/baz'
		end

		it 'should allow concatenate Flame::Path object to Strings' do
			('/foo' + @init.call('/bar', 'baz')).should.equal '/foo/bar/baz'
		end
	end

	describe '#to_routes_with_endpoint' do
		it 'should return the nested Hash with path parts as keys with endpoint' do
			path = @init.call('/foo/bar/baz')
			routes, endpoint = path.to_routes_with_endpoint
			routes.should.equal('foo' => { 'bar' => { 'baz' => {} } })
			endpoint.should.equal({})
			endpoint.should.be.same_as routes.dig(*path.parts)
		end
	end
end
