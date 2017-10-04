require "spec_helper"


RSpec.describe AwsTestDump do
  it "has a version number" do
    expect(AwsTestDump::VERSION).not_to be nil
  end

  it "retores schema and data from test directory" do
    if !ENV['DYNAMO_ENDPOINT'].nil? && ENV['AWS_ACCESS_KEY_ID'] == 'potato'
      schema_processor = AwsTestDump::DynamoSchemaRestore.new
      schema_processor.run
      data_processor = AwsTestDump::DynamoDataRestore.new
      data_processor.run
    end
  end

end
