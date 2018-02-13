require 'aws-sdk-core'
require 'aws-sdk-s3'
require 'faker'
require "spec_helper"


RSpec.describe 'S3FileDump' do
  it "has a version number" do
    expect(AwsTestDump::VERSION).not_to be nil
  end

  it "restores dumped file to fakes3" do
    bucket = 'some_bucket'
    key = 'rubber-duck.jpg'

    file_restore = AwsTestDump::S3Restore.new
    file_restore.run

    file_dump = AwsTestDump::S3FileDump.new(bucket, key)
    file_dump.run
  end

end
