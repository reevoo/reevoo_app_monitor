# ReevooLogger

ReevooLogger consolidates logstasher, statsd and sentry raven into a single library with one setup. It automatically
tracks all log messages into logstash, exceptions into sentry and updates exceptions stats in statsd. It also allow you
to call methods directly on instances of statsd and raven if needed.

## Installation

### In your Gemfile:

```ruby
gem 'reevoo_logger'
```

### Init logger:

```ruby
module TestApp
  def self.logger
    @logger ||= ReevooLogger.new(
      app_name: "foo_app",
      root_dir: Rack::Directory.new("").root
      device: STDOUT, # default is file log in log/logstasher.log
      raven_conf: {
        dns: "https://00c73aa8f93f4hbwjehb4r20af10afb@app.getsentry.com/502146" # public sentry DNS
      },
      statsd_conf: { # in most cases you should be fine with default localhost:8125
        host: "my-host",
        port: 1234
      }
    )
  end
end
```


### Setup Grape request/exception logging

Add to Gemfile

```ruby
gem 'grape_logging'
```

Setup in Grape::API class

```ruby
module TestApp
  class API < Grape::API
    logger TestApp.logger
    use GrapeLogging::Middleware::RequestLogger, logger: TestApp.logger

    rescue_from TestApp::NotFound do |err|
      # Tag your exception
      API.logger.info(exception: err, tags: "rescued_exception", status: 404)
      error_response(message: "Not found", status: 404)
    end

    rescue_from :all do |e|
      API.logger.error(e)
      error_response(message: e.message, status: 500)
    end
  end
end
```


### Using statsd directly

```ruby
  TestApp.logger.statsd.increment('foo.bar')
```

### Using raven directly

```ruby
  TestApp.logger.raven.capture_exception(exception)
```


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
