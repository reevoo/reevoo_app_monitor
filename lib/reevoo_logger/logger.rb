require 'active_support/core_ext/string/inflections'
require 'logger'

module ReevooLogger
  class Logger < ::Logger

    def initialize(statsd, device)
      super(device)
      @statsd = statsd
    end

    def add(severity, message = nil, progname = nil, &block)
      super

      return true unless progname.is_a?(Exception)

      # StatsD
      key ='exception.' + progname.class.to_s.underscore

      if message
        # Remove all non LATIN1 characters
        message_key = message.to_s.downcase.gsub(/[^a-zA-Z0-9]/, '_')

        # Use only first 100 characters
        key << '.' + message_key[0...100]
      end

      @statsd.increment(key)
    end

  end
end
