require 'spec_helper'
require 'statsd'

describe ReevooLogger::Logger do
  class TestError < StandardError
  end

  def test_exception(msg = nil)
    TestError.new(msg).tap do |err|
      err.set_backtrace([
        '/foo/bar.rb',
        '/my/root/releases/12345/foo/broken.rb',
        '/bar/foo.rb',
      ])
    end
  end

  subject { described_class.new(nil) }

  %w(debug info warn error fatal).each do |method_name|
    describe "##{method_name}" do
      let(:severity_const) { "Logger::#{method_name.upcase}".constantize }

      it 'calls #add and passes string' do
        expect(subject).to receive(:add).with(severity_const, nil, 'foo bar')
        subject.send(method_name, 'foo bar')
      end

      it 'calls #add and passes exception' do
        err = test_exception
        expect(subject).to receive(:add).with(severity_const, nil, err)
        subject.send(method_name, err)
      end

      it 'calls #add and passes hash' do
        msg = { exception: test_exception }
        expect(subject).to receive(:add).with(severity_const, nil, msg)
        subject.send(method_name, msg)
      end
    end
  end


  context 'statsd integration' do
    let(:statsd) { Statsd.new }
    subject { described_class.new(nil, statsd: statsd) }

    describe '#statsd' do
      it 'provides an instance of statsd' do
        expect(subject.statsd).to be_a(Statsd)
      end
    end

    describe '#add' do
      it 'tracks exceptions' do
        expect(statsd).to receive(:increment).with('exception.test_error', tags: ['severity:debug'])
        subject.add(Logger::DEBUG, nil, test_exception)
      end

      it 'tracks exceptions inside hash' do
        expect(statsd).to receive(:increment).with('exception.test_error', tags: ['severity:debug'])
        subject.add(Logger::DEBUG, nil, { exception: test_exception })
      end

      it 'omits all non exceptions' do
        expect(statsd).not_to receive(:increment)
        subject.add(Logger::DEBUG, nil, 'foo bar')
        subject.add(Logger::DEBUG, nil, { foo: 'bar' })
      end

      context 'with exception message' do
        it 'append a message' do
          expect(statsd).to receive(:increment).with('exception.test_error.foo_bar', tags: ['severity:info'])
          subject.add(Logger::INFO, nil, test_exception('Foo Bar'))
        end

        it 'replaces non-ASCII characters with _' do
          expect(statsd).to receive(:increment).with('exception.test_error.foo____bar', tags: ['severity:error'])
          subject.add(Logger::ERROR, nil, test_exception('Foo фф Bar'))
        end

        it 'replaces special characters with _' do
          expect(statsd).to receive(:increment).with(
            'exception.test_error.foo____________________________bar', tags: ['severity:warn']
          )
          subject.add(Logger::WARN, nil, test_exception(%q(Foo.,/?\][-=_+@£'";:><~`±§$%^&*Bar)))
        end

        it 'limits the message' do
          message =
            'long long long long long long long long long long long long long long long long long long long long message'

          expect(statsd).to receive(:increment) do |expected_message|
            # Exclude progname text and check the message size
            expected_message.gsub!('exception.test_error.', '')
            expect(expected_message.length).to eq(100)
          end
          subject.add(Logger::INFO, nil, test_exception(message))
        end
      end
    end
  end


  context 'raven integration' do
    let(:raven) { Raven }
    subject { described_class.new(nil, raven: raven) }

    describe '#raven' do
      it 'provides an instance of raven' do
        expect(subject.raven).to eq(Raven)
      end
    end

    describe '#add' do
      it 'tracks exceptions' do
        err = test_exception
        expect(raven).to receive(:capture_exception).with(err, tags: { severity: 'error' })
        subject.add(Logger::ERROR, nil, err)
      end

      it 'tracks exceptions inside hash' do
        err = test_exception
        expect(raven).to receive(:capture_exception).with(err, tags: { severity: 'debug' })
        subject.add(Logger::DEBUG, nil, { exception: err })
      end

      it 'omits all non exceptions' do
        expect(raven).not_to receive(:capture_exception)
        subject.add(Logger::INFO, nil, 'foo bar')
        subject.add(Logger::ERROR, nil, { foo: 'bar' })
      end
    end
  end
end
