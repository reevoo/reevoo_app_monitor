# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'reevoo_app_monitor/version'

Gem::Specification.new do |spec|
  spec.name          = "reevoo_app_monitor"
  spec.version       = ReevooAppMonitor::VERSION
  spec.authors       = ["Alex Malkov", "David Sevcik"]
  spec.email         = ["alex.malkov@reevoo.com", "david.sevcik@reevoo.com"]

  spec.summary       = %q{Produces log in the logstash format with ability to log events into DataDog}
  spec.description   = %q{Produces log in the logstash format with ability to log events into DataDog}
  spec.homepage      = "https://github.com/reevoo/reevoo_app_monitor"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rv-logstasher", "~> 1.5"
  spec.add_dependency "dogstatsd-ruby", "~> 1.6"
  spec.add_dependency "sentry-raven", "~> 0.15.6"
  spec.add_dependency "activesupport"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
