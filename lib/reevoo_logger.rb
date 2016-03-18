require "reevoo_logger/version"
require "reevoo_logger/logger"
require 'logstasher'
require 'statsd'

module ReevooLogger

  def self.new_logger(app_name:, root_dir: nil, device: nil, level: nil, statsd_conf: {})
    formatter = LogStasher::LogFormatter.new(app_name, root_dir)
    device = set_device(device, root_dir)
    level ||= ::Logger::INFO

    statsd = ::Statsd.new(
      statsd_conf.fetch(:host, 'localhost'),
      statsd_conf.fetch(:port, 8125),
      namespace: app_name,
    )

    initialize_logger(statsd, device, level, formatter)
  end

  class << self

    def set_device(device, root_dir)
      return device if device
      return STDOUT unless root_dir

      log_dir = File.join(root_dir, 'log')
      Dir.mkdir(log_dir) unless File.exists?(log_dir)
      device = File.join(log_dir, 'logstasher.log')
      FileUtils.touch(device)
      device
    end

    def initialize_logger(statsd, device, level, formatter = nil)
      Logger.new(statsd, device).tap do |new_logger|
        new_logger.level     = level
        new_logger.formatter = formatter if formatter
      end
    end

  end
end
