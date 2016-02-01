# Flame

Flame is a small Ruby web framework, built on Rack,
inspired by Gin (which follows class-controllers style),
designed as a replacement Sintra, or maybe even Rails.

## Status

Flame still hardly suitable for production, but it's already possible to try,
and if you find flaws - please let me know.

## Installation

```
gem install flame
```

## Usage

```ruby
# index_controller.rb

class IndexController < Flame::Controller
    def index
        view :index
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

More at [Wiki](https://gitlab.com/AlexWayfer/flame/wikis/home) and in `example/` directory.

## Benchmark

| Framework            | Requests/sec | % from best |
| -------------------- | -----------: | ----------: |
| rack                 |     16909.34 |      100.0% |
| cuba                 |     12717.79 |      75.21% |
| rack-response        |     11574.86 |      68.45% |
| roda                 |     10487.95 |      62.02% |
| hanami-router        |      9053.25 |      53.54% |
| **flame**            |  **8636.36** |  **51.07%** |
| nyny                 |      5330.94 |      31.53% |
| gin                  |      5312.30 |      31.42% |
| scorched             |      4676.91 |      27.66% |
| sinatra              |      3945.21 |      23.33% |
| rails                |      3848.48 |      22.76% |

## TODO

* Create a command-line utility (for the generation of the project)
* ...