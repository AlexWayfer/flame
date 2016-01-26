# Flame

Flame is a small Ruby web framework, built on Rack, which follows class-controllers style.

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

More in `example/` directory.