# frozen_string_literal: true

describe Flame::Application::Config do
	before do
		@app_class = Class.new(Flame::Application)
		@hash = {
			foo: 1,
			bar: 2,
			baz: proc { 3 },
			another_baz: proc { |a| a * 2 }
		}
		@init = proc do |app: @app_class, hash: @hash|
			Flame::Application::Config.new(app, hash)
		end
		@config = @init.call
	end

	describe '#initialize' do
		it 'should recieve application' do
			config = @init.call(app: @app_class)
			config.instance_variable_get(:@app)
				.should.equal @app_class
		end

		it 'should recieve hash' do
			config = @init.call(hash: @hash)
			config.should.equal @hash
		end
	end

	describe '#[]' do
		it 'should behave like a Hash for regular values' do
			@config[:foo].should.equal 1
		end

		it 'should call procs without parameters from values' do
			@config[:baz].should.equal 3
			@config[:another_baz].should.be.kind_of Proc
		end
	end

	describe '#load_yaml' do
		before do
			@yaml = { foo: 1, bar: 'baz' }
		end

		it 'should load YAML file to #config' do
			@app_class.config.load_yaml 'example.yml'
			@app_class.config[:example].should.equal @yaml
		end

		it 'should load YAML file to #config by symbol basename' do
			@app_class.config.load_yaml :example
			@app_class.config[:example].should.equal @yaml
		end

		it 'should load YAML file to #config with other key' do
			@app_class.config.load_yaml :example, key: :another
			@app_class.config[:another].should.equal @yaml
		end

		it 'should load YAML file without allocating to #config' do
			yaml = @app_class.config.load_yaml :example, set: false
			yaml.should.equal @yaml
			@app_class.config[:example].should.equal nil
		end
	end
end
