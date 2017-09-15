require "aws_test_dump/version"


class NotValidOptionError < StandardError
end


def keep_keys(key_names, some_hash)
  some_hash.delete_if {|k, v| !key_names.include? k}
  some_hash.each_pair do |k,v|
    if v.is_a?(Hash)
      keep_keys(key_names, v)
    elsif v.is_a?(Array)
      v.each { |x| keep_keys(key_names, x) if x.is_a?(Hash)}
    end
  end
  some_hash
end


module AwsTestDump
  require 'aws-sdk-core'
  require 'fileutils'
  require 'yaml'

  DATA_DUMP_DEFINITION = ENV['DATA_DUMP_DEFINITION'] || File.join(Dir.pwd, 'spec', 'test_data_dump_definition.rb')
  require_relative DATA_DUMP_DEFINITION

  Aws.config[:region] = ENV['AWS_REGION']

  DEFAULT_DUMP_FILE = File.join(Dir.pwd, 'spec', 'dynamo_schema_dump.yml')
  DEFAULT_DATA_DUMP_DIR = File.join(Dir.pwd, 'spec', 'dynamo_data_dumps')
  DEFAULT_S3_DUMP_DIR = File.join(Dir.pwd, 'spec', 's3_test_files')
  DYNAMO_TABLE_FIELDS = %i(
    local_secondary_indexes
    global_secondary_indexes

    index_name
    projection
    projection_type
    non_key_attributes

    attribute_definitions
    key_schema
    provisioned_throughput

    attribute_name
    attribute_type
    key_type

    table_name
    read_capacity_units
    write_capacity_units
  )

  class BaseProcessor
    def run
      raise NotImplementedError
    end
  end

  class BaseDynamoProcessor < BaseProcessor
    attr_accessor :dump_file

    def initialize(dump_file=nil)
      dynamo_args = Hash.new
      dynamo_args[:endpoint] = ENV['DYNAMO_ENDPOINT'] if ENV['DYNAMO_ENDPOINT']
      @dynamo_client = Aws::DynamoDB::Client.new(**dynamo_args)
      @dump_file = dump_file
      @dump_file ||= DEFAULT_DUMP_FILE
    end

  end

  class S3BaseProcessor < BaseProcessor
    attr_accessor :bucket_name, :key_name

    def initialize(bucket_name, key_name)
      s3_args = Hash.new
      s3_args[:endpoint] = ENV['FAKES3_ENDPOINT'] if ENV['FAKES3_ENDPOINT']
      @s3_client = Aws::S3::Client.new(**s3_args)
      @bucket_name = bucket_name
      @key_name = key_name
      @dump_file = File.join(DEFAULT_S3_DUMP_DIR, bucket_name, key_name)
      @file_contents = nil
    end
  end

  class S3FileDump < S3BaseProcessor
    def run
      dump_data
    end

    def file_contents
      if @file_contents.nil?
        response = @s3_client.get_object(
          bucket: @bucket_name, key: @key_name
        ).body.read
        @file_contents = @key_name.end_with?('.json') ? JSON.pretty_generate(JSON.parse(response)) : response
      end
      @file_contents
    end

    def dump_data
      dirname = File.dirname(@dump_file)
      unless File.directory?(dirname)
        FileUtils.mkdir_p(dirname)
      end
      File.open(@dump_file, 'w') { |file| file.write file_contents }
    end
  end

  class S3FileRestore < S3BaseProcessor
    def run
      restore
    end

    def file_contents
      if @file_contents.nil?
        @file_contents = File.read(@dump_file)
      end
      @file_contents
    end

    def restore
      puts @bucket_name
      puts @key_name
      @s3_client.create_bucket({bucket: @bucket_name})
      @s3_client.put_object({bucket: @bucket_name, key: @key_name, body: file_contents})
    end
  end

  class S3Restore < BaseProcessor
    def initialize
      @s3_files = nil
      @s3_restore_processors = Array.new
    end

    def run
      s3_restore_processors.each { |x| x.run }
    end

    def s3_files
      if @s3_files.nil?
        @s3_files = Dir[ File.join(DEFAULT_S3_DUMP_DIR, '**', '*') ].reject { |p| File.directory? p }
      end
      @s3_files
    end

    def s3_restore_processors
      if @s3_restore_processors.empty?
        s3_files.each do |s3_file|
          relative_path = s3_file.split(DEFAULT_S3_DUMP_DIR)[1][1..-1]
          bucket = relative_path.split('/')[0]
          key = relative_path.gsub(bucket, '')[1..-1]
          @s3_restore_processors << S3FileRestore.new(bucket, key)
        end
      end
      @s3_restore_processors
    end
  end


  class DynamoTableDump < BaseDynamoProcessor
    attr_accessor :table_name, :data_dump_definition

    def initialize(data_dump_definition)
      super
      @table_name = data_dump_definition[:table_name]
      @dump_file = File.join(
        DEFAULT_DATA_DUMP_DIR, "#{data_dump_definition[:table_name]}.yml"
      )
      @data_dump_definition = data_dump_definition
      @query_results = nil
    end

    def run
      dump_data
    end

    def dump_data
      data = {table_name: @table_name, data: query_results}
      File.open(@dump_file, 'w') { |file| file.write data.to_yaml }
    end

    def _query
      @dynamo_client.query({
        :table_name => @table_name,
        :select => 'ALL_ATTRIBUTES',
        :key_conditions => @data_dump_definition[:key_conditions]
      })
    end

    def _scan
      @dynamo_client.scan({:table_name => @table_name})
    end

    def query_results
      if @query_results.nil?
        response = !@data_dump_definition[:key_conditions].nil? ? _query : _scan
        @query_results = response.items
      end
      @query_results
    end

  end

  class DynamoDataDump < BaseDynamoProcessor
    attr_accessor :table_name, :data_dump_definitions

    def initialize(table_name=nil)
      super
      @table_name = table_name
      @data_dump_definitions = nil
    end

    def data_dump_definitions
      if @data_dump_definitions.nil?
        if !@table_name.nil?
          @data_dump_definitions = [DATA_DUMP_DEFINITIONS.find { |x| x[:table_name] == table_name }]
        else
          @data_dump_definitions = DATA_DUMP_DEFINITIONS
        end
      end
      @data_dump_definitions
    end

    def run
      data_dump_definitions.each do |data_dump_definition|
        dynamo_table_dump = DynamoTableDump.new data_dump_definition
        dynamo_table_dump.run
      end
    end
  end

  class DynamoTableDataRestore < BaseDynamoProcessor
    def initialize(dump_file)
      super dump_file
      @table_name = nil
      @data = nil
      @data_dump_definition = nil
    end

    def run
      data.each_with_index do |item, index|
        if index == 0
          item.merge!(data_dump_definition.fetch(:replace_first, Hash.new))
        end
        item.merge!(data_dump_definition[:replace_these])
        @dynamo_client.put_item({:table_name => table_name, item: item})
      end
    end

    def parse_file
      file_contents = YAML.load(File.open(@dump_file))
      @table_name = file_contents[:table_name]
      @data = file_contents[:data]
    end

    def data_dump_definition
      if @data_dump_definition.nil?
        @data_dump_definition = DATA_DUMP_DEFINITIONS.find { |x| x[:table_name] == table_name}
      end
      @data_dump_definition
    end

    def table_name
      parse_file if @table_name.nil?
      @table_name
    end

    def data
      parse_file if @data.nil?
      @data
    end
  end

  class DynamoDataRestore < BaseDynamoProcessor

    def initialize
      super
      @data_dump_files = Array.new
    end

    def data_dump_files
      if @data_dump_files.empty?
        Dir.entries(DEFAULT_DATA_DUMP_DIR).each do |f|
          full_path = File.join(DEFAULT_DATA_DUMP_DIR, f)
          @data_dump_files << full_path if File.file?(full_path)
        end
      end
      @data_dump_files
    end

    def run
      data_dump_files.each do |f|
        dynamo_table_data_restore = DynamoTableDataRestore.new(f)
        dynamo_table_data_restore.run
      end
    end
  end

  class DynamoSchemaDump < BaseDynamoProcessor
    attr_accessor :table_names, :schemata

    def initialize(dump_file=nil)
      super dump_file
      @table_names = nil
      @schemata = nil
    end

    def run
      dump_schemata
    end

    def dump_schemata
      File.open(@dump_file, 'w') { |file| file.write schemata.to_yaml }
    end

    def table_names
      if @table_names.nil?
        @table_names = @dynamo_client.list_tables.table_names
      end
      @table_names
    end

    def schemata
      if @schemata.nil?
        @schemata = Array.new
        table_names.each do |table_name|
          table_schema = @dynamo_client.describe_table(table_name: table_name).to_h[:table]
          keep_keys(DYNAMO_TABLE_FIELDS, table_schema)
          @schemata << table_schema
        end
      end
      @schemata
    end

  end

  class DynamoSchemaRestore < BaseDynamoProcessor
    attr_accessor :schemata

    def initialize(dump_file=nil)
      super dump_file
      @schemata = nil
    end

    def run
      create_tables
    end

    def create_tables
      schemata.each do |schema|
        begin
          @dynamo_client.create_table(schema)
        rescue Aws::DynamoDB::Errors::ResourceInUseException
        end
      end
    end

    def schemata
      if @schemata.nil?
        @schemata = YAML.load(File.open(@dump_file))
      end
      @schemata
    end
  end
end
