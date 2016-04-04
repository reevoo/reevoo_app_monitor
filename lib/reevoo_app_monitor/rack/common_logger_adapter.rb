require "logstasher/rack/common_logger_adapter"

class ReevooAppMonitor
  module Rack
    class CommonLoggerAdapter < LogStasher::Rack::CommonLoggerAdapter
    end
  end
end
