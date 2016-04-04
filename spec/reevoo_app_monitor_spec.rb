require 'spec_helper'

describe ReevooAppMonitor do

  let(:app_name) { 'foo' }
  let(:root_dir) { nil }
  let(:device) { nil }
  let(:statsd_conf) { {} }
  let(:options) do
    {
      app_name:    app_name,
      root_dir:    root_dir,
      device:      device,
      statsd_conf: statsd_conf,
    }
  end

  subject { described_class.new(options) }

  describe '.new' do
    context 'when just app_name provided' do
      it 'returns logger instance with default setup' do
        expect(subject.logger).to be_a(ReevooAppMonitor::Logger)
      end

      it 'defaults the log level to INFO' do
        expect(subject.logger.level).to eq(Logger::INFO)
      end
    end

    context 'when no device provided' do
      context 'and no root_dir' do
        it 'sets device to STDOUT' do
          device = subject.logger.instance_variable_get(:@logdev)
          expect(device.instance_variable_get(:@dev)).to eq(STDOUT)
        end
      end

      context 'and with root_dir' do
        let(:root_dir) { Dir.pwd }
        it 'sets device to the root_dir' do
          device = subject.logger.instance_variable_get(:@logdev)
          expect(device.instance_variable_get(:@dev)).to be_a(File)
          expect(device.instance_variable_get(:@dev).path).to include(root_dir + '/log/logstasher.log')
        end
      end
    end

    context 'when device provided' do
      let(:device) { STDERR }
      it 'sets device to STDOUT' do
        device = subject.logger.instance_variable_get(:@logdev)
        expect(device.instance_variable_get(:@dev)).to eq(STDERR)
      end
    end
  end

  describe '#stats' do
    it 'provides an instance with methods increment, histogram, gauge, time' do
      expect(subject.stats.respond_to?(:increment)).to eq(true)
      expect(subject.stats.respond_to?(:histogram)).to eq(true)
      expect(subject.stats.respond_to?(:gauge)).to eq(true)
      expect(subject.stats.respond_to?(:time)).to eq(true)
    end
  end
end
