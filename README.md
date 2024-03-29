<p align="center">
    <img
        src="https://raw.githubusercontent.com/AlexWayfer/flame/main/public/favicon.ico"
        height="150"
        alt="Flame Logo"
        title="Logo from open-source Elusive-Iconfont (https://github.com/reduxframework/elusive-iconfont)"
    />
</p>

<h1 align="center">Flame</h1>

<p align="center">
    <a href="https://cirrus-ci.com/github/AlexWayfer/flame/main"><img
        src="https://api.cirrus-ci.com/github/AlexWayfer/flame.svg?branch=main"
        alt="Cirrus CI"
    /></a>
    <a href="https://codecov.io/gh/AlexWayfer/flame"><img
        src="https://img.shields.io/codecov/c/github/AlexWayfer/flame.svg?style=flat-square"
        alt="Codecov"
    /></a>
    <a href="https://codeclimate.com/github/AlexWayfer/flame"><img
        src="https://img.shields.io/codeclimate/maintainability/AlexWayfer/flame.svg?style=flat-square"
        alt="Code Climate"
    /></a>
    <a href="https://depfu.com/repos/AlexWayfer/flame"><img
        src="https://img.shields.io/depfu/AlexWayfer/flame.svg?style=flat-square"
        alt="Depfu"
    /></a>
    <a href="http://inch-ci.org/github/AlexWayfer/flame"><img
        src="http://inch-ci.org/github/AlexWayfer/flame.svg?branch=main&style=flat-square"
        alt="Docs"
    /></a>
    <a href="https://rubygems.org/gems/flame"><img
        src="https://img.shields.io/gem/v/flame.svg?include_prereleases&style=flat-square"
        alt="Gem (including prereleases)"
    /></a>
    <a href="https://github.com/AlexWayfer/flame/blob/main/LICENSE.txt"><img
        src="https://img.shields.io/github/license/AlexWayfer/flame.svg?style=flat-square"
        alt="MIT license"
    /></a>
</p>

Flame is a small Ruby web framework, built on [Rack](https://github.com/rack/rack),
inspired by [Gin](https://github.com/jcasts/gin) (which follows class-controllers style),
designed as a replacement [Sinatra](https://github.com/sinatra/sinatra)
or maybe even [Rails](https://github.com/rails/rails).

## Why?

I didn't like class methods, especially for controller's hooks — OOP is prettier without it.
And I found a way to implement controller's hooks without using class methods,
but with the inheritance (including the including of modules).
Moreover, with class methods an insufficiently obvious order of hooks (especially with inheritance)
and complicated implementation of conditions are obtained.
In this framework everything is Ruby-native as it can be.

## Installation

Using the built-in `gem`:

```bash
$ gem install flame
```

or with [Bundler](http://bundler.io/):

```ruby
# Gemfile
gem 'flame'
```

## Usage

The simplest example:

```ruby
# index_controller.rb

class IndexController < Flame::Controller
  def index
    view :index # or just `view`, Symbol as method-name by default
  end

  def hello_world
    "Hello World!"
  end

  def goodbye
    "Goodbye World!"
  end
end

# app.rb

class App < Flame::Application
  mount IndexController do
    # all methods will be mounted automatically, it's just an example of refinement
    get '/hello', :hello_world
  end
end

# config.ru

require_relative './index_controller'

require_relative './app'

run App.new # or `run App`
```

More at [Wiki](https://github.com/AlexWayfer/flame/wiki).

## Benchmark

The last benchmark can be viewed [here](https://github.com/luislavena/bench-micro).

## Development

After checking out the repo, run `bundle install` to install dependencies.

Then, run `toys rspec` to run the tests.

To install this gem onto your local machine, run `toys gem install`.

To release a new version, run `toys gem release %version%`.
See how it works [here](https://github.com/AlexWayfer/gem_toys#release).

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/AlexWayfer/flame).

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
