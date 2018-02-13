# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aws_test_dump/version'

Gem::Specification.new do |spec|
  spec.name          = "aws_test_dump"
  spec.version       = AwsTestDump::VERSION
  spec.authors       = ["Daniel Hanson"]
  spec.email         = ["daniel.hanson82@gmail.com"]

  spec.summary       = %q{simple script for dumping and restoring aws test data for local testing}
  spec.homepage      = "https://github.com/DanHanson82/ruby-aws-test-dump"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.executables   = ["aws_test_dump"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "aws-sdk", "~> 3"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 12"
  spec.add_development_dependency "rspec", "~> 3"
  spec.add_development_dependency "simplecov", "~> 3"
end
