require "reevoo_app_monitor/version"
require "reevoo_app_monitor/logger"
require "reevoo_app_monitor/nil_service"
require "logstasher"
require "statsd"
require "raven/base"

class ReevooAppMonitor
  DEFAULT_INTEGRATIONS = [:logstasher, :statsd, :raven]

  attr_reader :logger, :stats

  def initialize(app_name:, root_dir: nil, device: nil, level: ::Logger::INFO,
      env: ENV["RACK_ENV"], integrations: DEFAULT_INTEGRATIONS, statsd_conf: {}, raven_conf: {})

    @stats = init_statsd(statsd_conf, app_name, env)              if integrations.include?(:statsd)
    raven = init_raven(raven_conf, app_name, env)                 if integrations.include?(:raven)
    formatter = LogStasher::LogFormatter.new(app_name, root_dir)  if integrations.include?(:logstasher)

    device ||= get_device(root_dir)
    @logger = init_logger(device, level, formatter, statsd: @stats, raven: raven)
  end

  def nil_service
    @nil_service ||= ReevooAppMonitor::NilService.new
  end

  private

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
      config.silence_ready = true
      raven_conf.each_pair { |key, value| config.send("#{key}=", value) }
    end
    Raven
  end
end
