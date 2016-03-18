require 'spec_helper'

describe ReevooLogger do
  it 'has a version number' do
    expect(ReevooLogger::VERSION).not_to be nil
  end

  describe '.new_logger' do
    let(:app_name) { 'foo' }
    let(:root_dir) { nil }
    let(:device) { nil }
    let(:level) { nil }
    let(:statsd_conf) { {} }
    let(:options) do
      {
        app_name:    app_name,
        root_dir:    root_dir,
        device:      device,
        level:       level,
        statsd_conf: statsd_conf,
      }
    end
    subject { described_class.new_logger(options) }

    context 'when just app_name provided' do
      it 'returns logger instance with default setup' do
        expect(subject).to be_a(ReevooLogger::Logger)
      end

      it 'defaults the log level to INFO' do
        expect(subject.level).to eq(Logger::INFO)
      end
    end

    context 'when no device provided' do
      context 'and no root_dir' do
        it 'sets device to STDOUT' do
          device = subject.instance_variable_get(:@logdev)
          expect(device.instance_variable_get(:@dev)).to eq(STDOUT)
        end
      end

      context 'and with root_dir' do
        let(:root_dir) { Dir.pwd }
        it 'sets device to the root_dir' do
          device = subject.instance_variable_get(:@logdev)
          expect(device.instance_variable_get(:@dev)).to be_a(File)
          expect(device.instance_variable_get(:@dev).path).to include(root_dir + '/log/logstasher.log')
        end
      end
    end

    context 'when device provided' do
      let(:device) { STDERR }
      it 'sets device to STDOUT' do
        device = subject.instance_variable_get(:@logdev)
        expect(device.instance_variable_get(:@dev)).to eq(STDERR)
      end
    end

    it 'provides an instance of statsd' do
      expect(subject.statsd).to be_a(Statsd)
    end

    class TestError < StandardError
    end

    let(:exception_message) { 'Exception message' }
    let(:exception) do
      e = TestError.new(exception_message)
      e.set_backtrace(backtrace)
      e
    end
    let(:backtrace) do
      [
        '/foo/bar.rb',
        '/my/root/releases/12345/foo/broken.rb',
        '/bar/foo.rb',
      ]
    end

    describe '#error' do
      it 'tracks error in statsd for exception' do
        expect_any_instance_of(Statsd).to receive(:increment).with('exception.test_error')
        subject.error(exception)
      end

      it 'tracks error in statsd for key exception' do
        expect_any_instance_of(Statsd).to receive(:increment).with('exception.test_error')
        # require 'pry'; binding.pry

        subject.error({exception: exception})
      end

      it 'tracks error in statsd for exception and message' do
        expect_any_instance_of(Statsd).to receive(:increment).with('exception.test_error.foo_bar')
        subject.error(message: 'Foo Bar', exception: exception)
      end
    end

    describe '#info' do
      it 'does not track an event in statsd if an exception provided' do
        expect_any_instance_of(Statsd).to_not receive(:increment)

        subject.info(exception)
      end

      it 'does not track an event in statsd if string provided' do
        expect_any_instance_of(Statsd).to_not receive(:increment)

        subject.info('exception')
      end
    end

    describe '#warn' do
      it 'does not track an event in statsd if an exception provided' do
        expect_any_instance_of(Statsd).to_not receive(:increment)

        subject.warn(exception)
      end

      it 'does not track an event in statsd if string provided' do
        expect_any_instance_of(Statsd).to_not receive(:increment)

        subject.warn('exception')
      end
    end

  end
end
