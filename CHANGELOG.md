# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

### Added

*   Add ability for controllers auto-mounting \
    Good bye giant application `mount` blocks! \
    But you can disable it with `nested: false` option for `mount`,
    for example, for conditional umbrella application.
*   Allow to mount anonymous controllers
*   Add support for Ruby 3.0 ­– 3.4
*   Add support of `OPTIONS` HTTP-method
*   Add `Application.require_dirs` method
*   Add `Controller#path_to_back` method
*   Add `:log_dir` for default config
*   Add `:require` option for `Config#load_yaml`
*   Receive options for Tilt in `Controller#(render|view)` method via `:tilt` argument
*   Add support of block for `Controller#render` method
*   Add metadata to Gem specification with links
*   Add required Ruby version into Gem specification
*   Add `Controller.with_actions` method for modules
    Example: `include with_actions ModuleWithActions`
*   Allow to render view by relative path from current view
*   Add ability for refining HTTP-methods of actions inside controllers \
    Now you can not use `post`, `patch` and others inside `mount` blocks, yay!
*   Catch `SyntaxError` for custom Internal Server Error page
*   Add `:only` option to `#with_actions` method
*   Add cache for `Controller#url_to` in production via `memery` gem
*   Add ability to refine actions in modules \
    Just `extend Flame::Controller::Actions` in module now,
    and than `include with_actions ThatModule`, as before.
*   Add `Flame::Router::Routes#to_s`, for routes printing
    ```ruby
    puts MyApplication.router.routes
    ```
*   Add `Request#headers` method (with Camel-Cased Hash)
*   Accept options for cookies setting
*   Add `Flame::Path#include?` method, forwarding to `#to_s`
*   Allow integration with `better_errors` gem \
    More info [here](https://github.com/BetterErrors/better_errors/issues/454).
*   Add RuboCop plugins, resolve offenses by them
*   Add `remark` Markdown linter


### Changed

*   Replace Array-based routes system with Hash-based
*   Move `flame` executable and `template/` to separated gem
    `flame-cli`, not required by default.
*   Take out `Config` from `Flame::Application` to `Flame` \
    Now it's possible to load config before routes (and models). \
    Also add `ConfigFileNotFoundError`.
*   Replace `URI` building with `Addressable::URI` from external gem
*   Replace `no-cache` with `public` and `max-age` (one year)
    for `Cache-Control` header for static files
*   Implemented 405 response instead of 404 for unavailable HTTP methods
*   Change format of mounting from constants to Symbols
*   Call `default_body` (for the nearest route) without `execute`
*   Switch from unsupported `bacon` to `minitest-bacon`, and then to RSpec
*   Replace `Controller.with_actions` with `.inherit_actions`
*   Move `Dispatcher#path_to` to `Application.path_to`
*   Replace `Controller#default_body` with `#not_found` for 404 pages,
    like `#server_error` for 500 pages.
*   Replace `URI.decode_www_form_component` with `CGI.unescape`
*   Reduce the number of violations of the Law of Demeter \
    Thanks to [@snuggs](https://github.com/snuggs)
*   Catch `invalid %-encoding`, halt 400
*   Improve `#inspect` output for custom Errors
*   Switch from Travis CI to Cirrus CI
*   Autoload `Render` module, don't eager require \
    I think it's unnecessary for API-like usage.
*   Slightly optimize `StaticFile`
*   Build query in `#path_to` from root-Hash \
    Now building a path with merged query parameters is easier, no more `params: {}`.
*   Run `Controller#not_found` through `execute` \
    For found nearest routes. \
    Now we can write before-hooks in `execute` also for nonexistent pages.
*   Don't assign results of `execute` (after-hooks) as `body`
*   Require directories starting with `_` first
*   Allow to redefine controller path with `PATH` constant inside
*   Update Rack and GorillaPatch
*   Update RuboCop to a new version, resolve new offenses
*   Improve version locks for dependencies
*   Use Depfu instead of closed Gemnasium

### Removed

*   Remove `Application#config` and `Application#router` methods
*   Remove Ruby < 2.7 support
*   Remove HTML tags (`<h1>`) from default body \
    There is no `Content-Type` HTTP header, also there is no reason to return exactly HTML content \
    (Flame can be used only for API or something else).

### Fixed

*   Fix issue with `nil` in after-hook which returned 404 status
*   Fix routing to path without an optional argument at the beginning
*   Fix routing for multiple routes starting with arguments \
    Example: parent controller with `show(id)` and nested controller at `/:parent_id/nested`.
*   Avoid new controller creation in `halt`
*   Fix typos in documentation

### Security

*   Fix exploit with static files \
    You could get the content of any file from the outside of public directory. \
    It did not work with `nginx`, Cloudflare or something else.


## 4.18.1 - 2017-06-29

### Added

*   Add `RouteArgumentsOrderError`
*   Add `TemplateNotFoundError` when file for rendering not found
*   Add `CODE_OF_CONDUCT.md`
*   Add `:version` option for `Controller#url_to` method with static files

### Changed

*   Remove ending slash from `Path#adapt` if initial path has all parameters
*   Rename `RouteArgumentsError` to `RouteExtraArgumentsError`

### Fixed

*   Fix `RouteArgumentsValidator#action_arguments` caching
*   Fix gem requiring in some cases

## 4.18.0 - 2017-06-27

### Added

*   Add parent actions inheritance without forbidden actions

### Changed

*   Improve `Controller#extract_params_for` method

## 4.17.0 - 2017-06-14

### Added

*   Add support of Modules for `with_actions` method

## 4.16.0 - 2017-06-09

### Changed

*   Return status from `Flame::Controller#redirect`

### Fixed

*   Fix body for rerouted action

## 4.15.2 - 2017-06-07

### Added

*   Add `Flame::Path#to_str` method for implicit conversion to String

## 4.15.1 - 2017-06-07

### Added

*   Add support of `Flame::Path` for `Controller#url_to`

## 4.15.0 - 2017-06-07

### Added

*   Add `Controller#reroute` method for executing another action

### Changed

*   Remove ending slash for `Path#adapt` to actions without parameters

### Fixed

*   Fix default path for nested `IndexController`

## 4.14.1 - 2017-05-29

### Added

*   Add `Path` class for more OOP

### Changed

*   Improve `Flame::Request#http_method` and comparing by it

## 4.14.0 - 2017-05-24

### Added

*   Add support of HTTP status as last argument for `Controller#redirect` method
*   Add support of `Controller#redirect` as argument for `Dispatcher#halt`

### Changed

*   Return `nil` from `Controller#redirect` method

## 4.13.0 - 2017-05-19

### Added

*   Add support of `HEAD` HTTP method

### Changed

*   Return upcased symbolized HTTP method from `Flame::Request#http_method`

## 4.12.4 - 2017-05-17

### Changed

*   Add comparing by first argument including in path parts for Routes sorting

## 4.12.3 - 2017-05-17

### Added

*   Add support of `URI` objects for `redirect` method

### Changed

*   Move cached views from `Flame::Render` to `Application`
*   Improve view files search by controller name \
    Don't remove extra (logical) `controller` parts.

### Fixed

*   Display default body for status (500) if controller has not initialized
    Don't raise another (the second) exception.

## 4.12.2 - 2017-05-04

### Changed

*   Improve default body rendering

## 4.12.1 - 2017-04-27

### Fixed

*   Fix many errors in 4.12.0

## 4.12.0 - 2017-04-27

### Added

*   Add specs
*   Add Travis CI integration
*   Add Code Climate integration

### Changed

*   Update Ruby target version in RuboCop to 2.3
*   Remove trailing slash for `path_to` without optional arguments
*   Replace two different errors about Route arguments \
    with one `RouteArgumentsError`
*   Require status for `halt` method before body
*   Move `Content-Type` writer from Dispatcher to Response
*   Try to find and return static files before routes

### Removed

*   Remove unnecessary Actions Validator

### Fixed

*   Fix dependencies and their versions
*   Fix issue with default body from Flame
*   Fix issue with frozen path in `path_to`
*   Fix offenses from new RuboCop version

## 4.11.3.2 - 2017-02-27

### Changed

*   Use [`rack-slashenforce`](https://github.com/AlexWayfer/rack-slashenforce) \
    instead of custom (built) implementation.

## 4.11.3.1 - 2017-02-26

### Fixed

*   Fix critical bug with static files

## 4.11.3 - 2017-02-25

### Added

*   Add `Cache-Control: no-cache` header for responses with static files

### Changed

*   Make methods for static files in Dispatcher private

### Fixed

*   Fix `gemspec` require
*   Fix content type for attachments

## 4.11.2 - 2017-02-21

### Fixed

*   Fix views as symbolic links

## 4.11.1 - 2017-02-21

### Added

*   Add `halt` method for controllers

## 4.11.0 - 2017-02-20

### Added

*   Add support of actions optional arguments values
*   Add more methods for Controller delegation from Dispatcher

### Changed

*   Replace `rescue` in `execute` with `server_error` private method

### Fixed

*   Fix views files search

## 4.10.0 - 2017-01-24

### Added

*   Add redirect from request with many trailing slashes to path without them

## 4.9.0 - 2017-01-24

### Added

*   Add cache option for views render

## 4.8.1 - 2017-01-24

### Fixed

*   Fix layouts for `PlainTemplate`

## 4.8.0 - 2017-01-20

### Changed

*   Make `defaults` method for routes refines not required

## 4.7.4 - 2017-01-17

### Added

*   Add RuboCop as development dependency, resolve some offenses

### Changed

*   Update `gorilla-patch` to version `2`

## 4.7.3 - 2017-01-17

### Added

*   Add `Controller.actions` shortcut method

## 4.7.2 - 2016-12-28

### Added

*   Add `:tmp_dir` for `Application#config`

## 4.7.1 - 2016-12-16

### Added

*   Add `PATCH` HTTP-method for routes refines

## 4.7.0 - 2016-11-15

### Removed

*   Remove String keys from `params`, leave only Symbol

## 4.6.2 - 2016-11-10

### Changed

*   Update `gorilla-patch` to version `1.0.0`

## 4.6.1 - 2016-11-08

### Changed

*   Update gemspec syntax

## 4.6.0 - 2016-10-31

### Added

*   Add support of `:params` argument for `path_to` method

## 4.5.1 - 2016-10-20

### Added

*   Add support of `false` value for layout render option

## 4.5.0 - 2016-09-27

### Changed

*   Improve parent actions inheritance

## 4.4.6 - 2016-09-22

### Added

*   Add method to inherit actions from superclass

## 4.4.6 - 2016-09-22

### Added

*   Add method to inherit actions from superclass

## 4.4.5.1 - 2016-09-12

### Fixed

*   Update `gorilla-patch` to fixed version

## 4.4.5 - 2016-09-12

### Fixed

*   Symbolize `params` keys nested in Arrays

## 4.4.4 - 2016-08-01

### Changed

*   Update `rack` and `tilt` dependencies

## 4.4.3 - 2016-04-21

### Added

*   Add port (after host) for `url_to` method

## 4.4.3 - 2016-04-21

### Added

*   Add port (after host) for `url_to` method

## 4.4.2 - 2016-04-12

### Fixed

*   Fix `default_body` for static files

## 4.4.1 - 2016-04-12

### Fixed

*   Fix bugs with `default_body` invoking

## 4.4.0.1 - 2016-04-12

### Fixed

*   Fix 404 (after previous change)

## 4.4.0 - 2016-04-12

### Changed

*   Replace `not_found` method with `default_body` and halting, for 404

## 4.3.5 - 2016-04-01

### Fixed

*   Fix nested layouts sorting

## 4.3.4 - 2016-03-31

### Added

*   Add `url_to` helper method for building full URL from controller

## 4.3.3 - 2016-03-23

### Added

*   Add support of views filenames as downcased controller name \
    when actions is `index`

## 4.3.2 - 2016-03-10

### Fixed

*   Fix issue with cache of non-rendered

## 4.3.1 - 2016-03-10

### Fixed

*   Fix non-Symbol nested keys in request `params`

## 4.3 - 2016-03-10

### Added

*   Add support of view render with multiple layouts

## 4.2.1 - 2016-03-02

### Changed

*   Make `Flame::Render` work with cache

## 4.2.1 - 2016-03-02

### Changed

*   Make `Flame::Render.tilts` public

## 4.2.0 - 2016-03-02

### Added

*   Add executable with `new` subcommand

## 4.1.0 - 2016-03-02

### Added

*   Add method for loading YAML files to Application

## 4.0.16 - 2016-02-16

### Fixed

*   Fix static files for Unicode filenames

## 4.0.15 - 2016-02-16

### Changed

*   Improve views directories search (add more variants)

## 4.0.15 - 2016-02-16

### Changed

*   Improve views directories search (more variants)

## 4.0.14 - 2016-02-16

### Added

*   Add `:index` action as default for `path_to` helper method

## 4.0.13 - 2016-02-15

### Added

*   Add `content_type` and `attachment` helper methods for Dispatcher

## 4.0.12 - 2016-02-15

### Changed

*   Take underscored preceding module name if controller is `IndexController`

## 4.0.11 - 2016-02-10

### Changed

*   Improve views directories search

## 4.0.10 - 2016-02-10

### Changed

*   Remove `index` part from directories of views for controller

## 4.0.9 - 2016-02-08

### Fixed

*   Fix fatal issues from version 4.0.8

## 4.0.8 - 2016-02-08

### Changed

*   Change Route class, fix many default-path-build errors

## 4.0.7.2 - 2016-02-07

### Fixed

*   Fix `ArgumentNotAssignedError` raising

## 4.0.7.1 - 2016-02-07

### Fixed

*   Fix dependencies

## 4.0.7 - 2016-02-05

### Changed

*   Improve templates and layouts search

## 4.0.6 - 2016-02-04

### Added

*   Add support of protected `Controller#execute` methods

### Fixed

*   Fix `GorillaPatch` usage
*   Fix error raising in `path_to` (for nonexistent route)

## 4.0.5 - 2016-02-03

### Added

*   Dump exception from Dispatcher if not dumped from Controller

### Changed

*   Improve default paths for controllers

## 4.0.4 - 2016-02-03

### Added

*   Add version file (and `Flame::VERSION` constant)

## 4.0.3 - 2016-02-02

### Added

*   Add internal helper method for plugins

## 4.0.2 - 2016-02-01

### Changed

*   Relax `tilt` dependency
*   Return `nil` when template not found instead of 404

### Fixed

*   Fix default REST actions

## 4.0.1 - 2016-02-01

### Changed

*   Nest Validators, Errors and Route from root (`Flame`) namespace

## 4.0.0 - 2016-01-29

### Changed

*   Make hooks as code in `Controller#execute` method (before and after `super`)
*   Documentation (YARD) added!

## 3.6.3 - 2016-01-27

### Changed

*   Improve controllers templates folder searching

## 3.6.2 - 2016-01-26

### Fixed

*   Fix 404 error

## 3.6.1 - 2016-01-26

### Changed

*   Make empty string as default body

## 3.6.0 - 2016-01-26

### Added

*   Add `body` (united reader and writer) method

## 3.5.2 - 2016-01-26

### Added

*   Add `Content-Type: text/html` header for default body

## 3.5.1 - 2016-01-26

### Fixed

*   Fix 404 without nearest route

## 3.5.0 - 2016-01-26

### Added

*   Add hooks for errors

### Changed

*   Fix and improve many things

## 3.4.0 - 2016-01-11

### Removed

*   Remove middlewares and `Flame::Application.use` method \
    Use `rackup` for this.

## 3.3.4 - 2015-12-10

### Changed

*   Make "all actions" as default for `after` and `before` hooks

## 3.3.3 - 2015-12-09

### Added

*   Add Symbol keys in `params` alongside of String

## 3.3.2 - 2015-12-07

### Changed

*   Make `:index` as default action for `path_to`

## 3.3.1 - 2015-12-07

### Fixed

*   Fix error when body is `OK` instead of empty

## 3.3.0 - 2015-12-07

### Added

*   Add support of `RACK_ENV` environment variable
*   Add `:cache` option for `render` method (enabled by default)

### Fixed

*   Fix templates

## 3.2.1 - 2015-12-07

### Changed

*   Make default path for `IndexController` equal to `/`

## 3.2.0 - 2015-12-03

### Added

*   Add `helpers` method for applications

### Changed

*   Make Dispatcher as class, large refactoring

## 3.1.4 - 2015-11-25

### Added

*   Add `:config_dir` for `Application#config`

## 3.1.3.1 - 2015-11-25

### Fixed

*   Fix error with `nil` action in routes refines

## 3.1.3 - 2015-11-16

### Changed

*   Make path for routes refines not required

## 3.1.2 - 2015-11-09

### Fixed

*   Fix default paths of controllers

## 3.1.1 - 2015-11-09

### Added

*   Add (recursive) `mount` method for routes refine

### Changed

*   Improve template searching in different possible directories
*   Make `path` argument of `Flame::Controller#view` method not required

### Fixed

*   Fix `Flame::Controller#path_to` method

## 3.1.0 - 2015-11-09

### Added

*   Add (recursive) `mount` method for routes refine

## 3.0.0 - 2015-11-08

### Changed

*   Make Controllers as classes, Dispatcher as helper module for Application

## 2.2.0 - 2015-11-06

### Added

*   Add `after` method (hook) for routes refine

## 2.1.1 - 2015-11-03

### Added

*   Add `Rack::Session::Pool` by default

## 2.1.0 - 2015-11-02

### Added

*   Add support for Rack middlewares in Flame applications

## 2.0.0 - 2015-10-28

### Changed

*   Remove `Controller` class, make controllers as modules

## 1.1.9 - 2015-10-25

### Changed

*   Set cookies for path `/`

## 1.1.8 - 2015-10-25

### Added

*   Add more helper methods for `Flame::Dispatcher` and controllers

### Fixed

*   Fix `scope` for layouts

## 1.1.2 - 2015-10-21

### Changed

*   Improve version locks for other dependencies

## 1.1.1.1 - 2015-10-21

### Changed

*   Improve version locks for dependencies

## 1.1.1 - 2015-10-21

### Changed

*   Add REST actions as default

## 1.1.0 - 2015-10-21

### Added

*   Add `Flame::Request` (`Rack::Request` wrapper)
*   Add `before` method for routes refine

## 1.0.6 - 2015-10-19

### Fixed

*   Fix Tilt-warnings
*   Fix views search for controllers

## 1.0.4 - 2015-10-14

### Added

*   Add helper methods for controllers

## 1.0.2 - 2015-10-08

### Fixed

*   Fix bug when a view layout is missing

## 1.0.1 - 2015-10-08

### Fixed

*   Fix error with 'tilt' dependency

## 1.0 - 2015-10-07

### Initial release
