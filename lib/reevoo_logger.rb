require "reevoo_logger/version"
require "reevoo_logger/logger"
require "logstasher"
require "statsd"
require "raven/base"

module ReevooLogger
  DEFAULT_INTEGRATIONS = [:logstasher, :statsd, :raven]

  def self.new_logger(app_name:, root_dir: nil, device: nil, level: ::Logger::INFO,
      env: ENV["RACK_ENV"], integrations: DEFAULT_INTEGRATIONS, statsd_conf: {}, raven_conf: {})

    formatter = LogStasher::LogFormatter.new(app_name, root_dir)  if integrations.include?(:logstasher)
    statsd = init_statsd(statsd_conf, app_name, env)              if integrations.include?(:statsd)
    raven = init_raven(raven_conf, app_name, env)                 if integrations.include?(:raven)

    device ||= get_device(root_dir)
    init_logger(device, level, formatter, statsd: statsd, raven: raven)
  end

  class << self

    def get_device(root_dir)
      return STDOUT unless root_dir

      log_dir = File.join(root_dir, 'log')
      Dir.mkdir(log_dir) unless File.exists?(log_dir)
      device = File.join(log_dir, 'logstasher.log')
      FileUtils.touch(device)
      device
    end

    def init_logger(device, level, formatter, statsd: nil, raven: nil)
      Logger.new(device, statsd: statsd, raven: raven).tap do |new_logger|
        new_logger.level     = level
        new_logger.formatter = formatter if formatter
      end
    end

    def init_statsd(statsd_conf, app_name, env)
      Statsd.new(
        statsd_conf.fetch(:host, 'localhost'),
        statsd_conf.fetch(:port, 8125),
        namespace: app_name,
        tags: ["env:#{env}"],
      )
    end

    def init_raven(raven_conf, app_name, env)
      Raven.configure do |config|
        config.tags = { env: env }
        raven_conf.each_pair { |key, value| config.send(key, value) }
      end
      Raven
    end

  end
end
