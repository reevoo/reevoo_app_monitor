require "reevoo_logger/version"
require "reevoo_logger/logger"

class ReevooLogger

  attr_reader :statsd

  def initialize(app_name:, root_dir: nil, device: nil, level: Logger::INFO, statsd_conf: {})
    if root_dir && !device
      device = File.join(root_dir, 'log', 'logstasher.log')
      FileUtils.touch(device)
    end
    formatter = LogStasher::LogFormatter.new(app_name, root_dir)

    @statsd = Statsd.new(
      statsd_conf.fetch(:host, 'localhost'),
      statsd_conf.fetch(:port, 8125),
      namespace: app_name,
    )

    initialize_logger(device || STDOUT, level, formatter)
  end

  private

  def initialize_logger(device = STDOUT, level = ::Logger::INFO, formatter = nil)
    Logger.new(@statsd, device).tap do |new_logger|
      new_logger.level = level
      new_logger.formatter = formatter if formatter
    end
  end

end
