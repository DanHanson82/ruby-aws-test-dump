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

  it "do a dump of the test schema and test data" do
    if !ENV['DYNAMO_ENDPOINT'].nil? && ENV['AWS_ACCESS_KEY_ID'] == 'potato'
      schema_processor = AwsTestDump::DynamoSchemaDump.new 'spec/tmp/dynamo_schema_dump.yml'
      schema_processor.run
      data_processor = AwsTestDump::DynamoDataDump.new nil, 'spec/tmp/dyno_dumps'
      data_processor.run
      data_processor = AwsTestDump::DynamoDataDump.new 'last_table', 'spec/tmp/dyno_dumps'
      data_processor.run
    end
  end

  it "retores schema and data from tmp dump directory" do
    if !ENV['DYNAMO_ENDPOINT'].nil? && ENV['AWS_ACCESS_KEY_ID'] == 'potato'
      schema_processor = AwsTestDump::DynamoSchemaRestore.new 'spec/tmp/dynamo_schema_dump.yml'
      schema_processor.run
      data_processor = AwsTestDump::DynamoDataRestore.new 'spec/tmp/dyno_dumps'
      data_processor.run
    end
  end
end
