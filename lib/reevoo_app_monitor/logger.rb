require 'active_support/core_ext/string/inflections'
require 'logger'

class ReevooAppMonitor
  class Logger < ::Logger

    def initialize(device, statsd: nil, raven: nil)
      super(device)
      @statsd = statsd
      @raven = raven
    end

    def add(severity, message = nil, progname = nil, &block)
      super

      # Naming of these arguments is weird, if no block is given to debug|info|warn|error|fatal method
      # it passes the message to #add as a progname and message argument is always nil. See the test for this class.
      exception = extract_exception(progname)
      tags = extract_tags(progname)
      track_exception_to_statsd(severity, exception, tags) if exception && @statsd
      track_exception_to_raven(severity, exception, tags) if exception && @raven
    end

    private

    def extract_exception(message)
      if message.is_a?(Exception)
        message
      elsif message.is_a?(Hash) && message[:exception] && message[:exception].is_a?(Exception)
        message[:exception]
      end
    end

    def extract_tags(message)
      message.is_a?(Hash) ? Array(message[:tags]) : []
    end

    def track_exception_to_statsd(severity, exception, tags)
      key_parts = ['exception', exception.class.to_s.underscore]
      if exception.message != exception.class.to_s # message is the class name if not provided when raising
        # Remove all non LATIN1 characters and get only first 100 characters
        key_parts << exception.message.downcase.gsub(/[^a-zA-Z0-9]/, '_')[0...100]
      end

      @statsd.increment(key_parts.join('.'), tags: ["severity:#{severity_text(severity)}"] + tags)
    end

    def track_exception_to_raven(severity, exception, tags)
      return if tags.include?("rescued_exception")
      options = { tags: { severity: severity_text(severity) } }
      options[:extra] = { extra_tags: tags } unless tags.empty?
      @raven.capture_exception(exception, options)
    end

    def severity_text(severity)
      format_severity(severity).downcase
    end

  end
end
