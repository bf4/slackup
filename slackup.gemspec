# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'slackup/version'

Gem::Specification.new do |spec|
  spec.name          = "slackup"
  spec.version       = Slackup::VERSION
  spec.authors       = ["Benjamin Fleischer"]
  spec.email         = ["dev@benjaminfleischer.com"]

  spec.summary       = %q{A simple tool to backup slack channels}
  spec.description   = %q{Backup slack channels with just a name and a token}
  spec.homepage      = "https://github.com/bf4/slackup"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "slack-api", "~> 1.1", ">= 1.1.3"
  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
end
