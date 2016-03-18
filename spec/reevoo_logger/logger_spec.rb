require 'spec_helper'
require 'statsd'

describe ReevooLogger::Logger do
  class TestError < StandardError
  end

  let(:statsd) { Statsd.new}

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

  subject { described_class.new(statsd, nil) }

  describe '#statsd' do
    it 'provides an instance of statsd' do
      expect(described_class.new(statsd, nil).statsd).to be_a(Statsd)
    end
  end

  describe '#add' do
    it 'tracks error in statsd' do
      expect(statsd).to receive(:increment).with('exception.test_error')
      subject.add(Logger::INFO, nil, exception)
    end

    context 'with message' do
      it 'append a message' do
        expect(statsd).to receive(:increment).with('exception.test_error.foo_bar')
        subject.add(Logger::INFO, 'Foo Bar', exception)
      end

      it 'replaces non-ASCII characters with _' do
        expect(statsd).to receive(:increment).with('exception.test_error.foo____bar')
        subject.add(Logger::INFO, 'Foo фф Bar', exception)
      end

      it 'replaces special characters with _' do
        expect(statsd).to receive(:increment).with('exception.test_error.foo____________________________bar')
        subject.add(Logger::INFO, %q(Foo.,/?\][-=_+@£'";:><~`±§$%^&*Bar), exception)
      end

      it 'limits the message' do
        message =
          'long long long long long long long long long long long long long long long long long long long long message'

        expect(statsd).to receive(:increment) do |expected_message|
          # Exclude progname text and check the message size
          expected_message.gsub!('exception.test_error.', '')
          expect(expected_message.length).to eq(100)
        end
        subject.add(Logger::INFO, message, exception)
      end

    end
  end

end
