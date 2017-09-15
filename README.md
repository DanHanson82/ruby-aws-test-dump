# AwsTestDump

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aws_test_dump'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install aws_test_dump

## Usage

### generating test data

#### dynamo data

The dynamo schema and test data is generated and restored using the aws_test_dump script.

To generate the schema, with real AWS credentials, run:

`aws_test_dump schema_dump`

To generate the test data, make sure the appropriate environment variables are set and an appropriate entry is entered in the spec/test_data_dump_definition.rb file.

An example entry:
```ruby
  {
    table_name: 'relation-customer-toe-analysis',
    key_conditions: {
      'customer_id' => {
        :attribute_value_list => [ENV['CUSTOMER_ID']],
        :comparison_operator => 'EQ'
      },
    },
    replace_these: {
      'customer_id' => ENV['CUSTOMER_ID'],
    },
    replace_first: {
      'toe_id' => ENV['TOE_ID'],
      'analysis_id' => ENV['ANALYSIS_ID'],
    },
  },
```
To create data dump files for each entry in the DATA_DUMP_DEFINITIONS, run:

`aws_test_dump data_dump`

and to create a dump of a specific table:

`aws_test_dump data_dump staging-export-analyses`


#### s3 data

To dump test s3 files, run the following in a racksh session with production aws credentials

```ruby
require_relative 'aws_test_dump'

bucket_name = 'some_bucket_name'
key_name = 'some_s3_file.json'
s3_dump = AwsTestDump::S3FileDump.new(bucket_name, key_name)
s3_dump.run
```

make sure any new buckets are added to the links mapping in the compose file so they are hitting the fakes3 service.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/DanHanson82/ruby-aws-test-dump. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

