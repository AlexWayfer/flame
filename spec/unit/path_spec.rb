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
		it 'should merge from array' do
			Flame::Path.merge(%w[foo bar baz])
				.should.equal 'foo/bar/baz'
		end

		it 'should merge from multiple parts' do
			Flame::Path.merge('/foo/bar', '/baz/bat')
				.should.equal '/foo/bar/baz/bat'
		end

		it 'should merge without extra slashes' do
			Flame::Path.merge('///foo/bar//', '//baz/bat///')
				.should.equal '/foo/bar/baz/bat/'
		end
	end

	describe '#initialize' do
		it 'should recieve path as String' do
			path = '/foo/bar'
			@init.call(path).to_s.should.equal path
		end

		it 'should recieve many path parts' do
			@init.call('/foo', '/bar', 'baz').to_s.should.equal '/foo/bar/baz'
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

		it 'should recieve String' do
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

	describe '#match?' do
		it 'should return false for missing fixed parts' do
			@path.match?('/none').should.equal false
		end

		it 'should return false for missing required arguments' do
			@path.match?('/foo/bar').should.equal false
		end

		it 'should return false for long path' do
			@path.match?('/foo/first/second/third/fourth').should.equal false
		end

		it 'should return true for all correct required arguments' do
			@path.match?('/foo/first/second').should.equal true
		end

		it 'should return true for all correct required and optional arguments' do
			@path.match?('/foo/first/second/third').should.equal true
		end

		it 'should receive Flame::Path' do
			@path.match?(@init.call('/foo/first/second/third')).should.equal true
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
end
