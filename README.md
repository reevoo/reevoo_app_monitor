# ReevooLogger

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/reevoo_logger`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

### In your Gemfile: 

```ruby
gem 'reevoo_logger'
```
    
### Init logger:
    
    module TestApp
      def self.logger
        @logger ||= ReevooLogger.new('app_name', Rack::Directory.new("").root)
      end
    end
    
You can specify the log output

    @logger ||= ReevooLogger.new('app_name', Rack::Directory.new("").root, STDOUT)
  

### Setup Grape request/exception logging

Add to Gemfile

    gem 'grape_logging'
    
Setup in Grape::API class
     
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


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

