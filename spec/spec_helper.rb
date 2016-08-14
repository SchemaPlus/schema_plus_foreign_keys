require 'simplecov'
require 'simplecov-gem-profile'
SimpleCov.start "gem"

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rspec'
require 'active_record'
require 'schema_plus_foreign_keys'
require 'schema_dev/rspec'

SchemaDev::Rspec.setup

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.include(SchemaPlus::Matchers)
  config.warnings = true
  config.around(:each) do |example|
    ActiveRecord::Migration.suppress_messages do
      begin
        example.run
      ensure
        ActiveRecord::Base.connection.data_sources.each do |table|
          ActiveRecord::Migration.drop_table table, force: :cascade
        end
      end
    end
  end
end

def with_fk_config(opts, &block)
  save = Hash[opts.keys.collect{|key| [key, SchemaPlus::ForeignKeys.config.send(key)]}]
  begin
    SchemaPlus::ForeignKeys.setup do |config|
      config.update_attributes(opts)
    end
    yield
  ensure
    SchemaPlus::ForeignKeys.setup do |config|
      config.update_attributes(save)
    end
  end
end

def define_schema(config={}, &block)
  with_fk_config(config) do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Schema.define do
        connection.data_sources.each do |table|
          drop_table table, force: :cascade
        end
        instance_eval &block
      end
    end
  end
end

SimpleCov.command_name "[ruby#{RUBY_VERSION}-activerecord#{::ActiveRecord.version}-#{ActiveRecord::Base.connection.adapter_name}]"
