# Flame

Flame is a small Ruby web framework,
built on [Rack](https://github.com/rack/rack),
inspired by [Gin](https://github.com/jcasts/gin)
(which follows class-controllers style),
designed as a replacement [Sinatra](https://github.com/sinatra/sinatra),
or maybe even [Rails](https://github.com/rails/rails).

## Status

Flame is ready to use in production, but if you find flaws - please let me know.

[![Gem Version](https://badge.fury.io/rb/flame.svg)](https://badge.fury.io/rb/flame)
[![Build Status](https://travis-ci.org/AlexWayfer/flame.svg?branch=master)](https://travis-ci.org/AlexWayfer/flame)
[![codecov](https://codecov.io/gh/AlexWayfer/flame/branch/master/graph/badge.svg)](https://codecov.io/gh/AlexWayfer/flame)
[![Code Climate](https://codeclimate.com/github/AlexWayfer/flame/badges/gpa.svg)](https://codeclimate.com/github/AlexWayfer/flame)
[![Dependency Status](https://gemnasium.com/badges/github.com/AlexWayfer/flame.svg)](https://gemnasium.com/github.com/AlexWayfer/flame)

## Why?

I don't like class methods, especially for controller's hooks — OOP is prettier without it. And I found a way to implement controller's hooks without using class methods, but with the inheritance (including the including of modules). Moreover, with class methods an insufficiently obvious order of hooks (especially with inheritance) and complicated implementation of conditions are obtained. In this framework everything is Ruby-native.

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
    get '/hello', :hello_world
    defaults
  end
end

# config.ru

require_relative './index_contoller'

require_relative './app'

run App.new # or `run App`
```

More at [Wiki](https://github.com/AlexWayfer/flame/wiki) and in `example/` directory.

## Benchmark

The last benchmark can be viewed [here](https://github.com/luislavena/bench-micro).
