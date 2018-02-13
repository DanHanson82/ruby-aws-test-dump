require "bundler/setup"
require 'simplecov'
require 'simplecov-console'

#
# SimpleCov must start before the application is required to measure coverage correctly
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::Console,
]
SimpleCov.start do
  add_filter "/spec/"
end
require "aws_test_dump"


abort("Not running tests with compose and fake aws credentials! View readme file!") if ENV['DYNAMO_ENDPOINT'].nil? && ENV['AWS_ACCESS_KEY_ID'] != 'chorizo'


RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
