require 'active_support/core_ext/string/inflections'
require 'logger'

class ReevooLogger
  class Logger < ::Logger

    def initialize(statsd, device)
      super(device)
      @statsd = statsd
    end

    def add(severity, message = nil, progname = nil, &block)
      super

      # StatsD
      @statsd.increment('exception.' + message.class.to_s.underscore) if message.is_a?(Error)
    end

  end
end
