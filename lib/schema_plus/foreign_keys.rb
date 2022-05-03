require 'schema_plus/core'
require 'schema_plus_compatibility'
require 'valuable'

require_relative 'foreign_keys/version'
require_relative 'foreign_keys/active_record/base'
require_relative 'foreign_keys/active_record/connection_adapters/abstract_adapter'
require_relative 'foreign_keys/active_record/connection_adapters/table_definition'
require_relative 'foreign_keys/active_record/connection_adapters/foreign_key_definition'
require_relative 'foreign_keys/active_record/migration/command_recorder'
require_relative 'foreign_keys/middleware/dumper'
require_relative 'foreign_keys/middleware/migration'
require_relative 'foreign_keys/middleware/model'
require_relative 'foreign_keys/middleware/mysql'
require_relative 'foreign_keys/middleware/sql'

module SchemaPlus::ForeignKeys
  module ActiveRecord
    module ConnectionAdapters
      autoload :Mysql2Adapter, 'schema_plus/foreign_keys/active_record/connection_adapters/mysql2_adapter'
      autoload :PostgresqlAdapter, 'schema_plus/foreign_keys/active_record/connection_adapters/postgresql_adapter'
      autoload :Sqlite3Adapter, 'schema_plus/foreign_keys/active_record/connection_adapters/sqlite3_adapter'
    end
  end

  # This global configuation options for SchemaPlus::ForeignKeys.
  # Set them in +config/initializers/schema_plus_foreign_keys.rb+ using:
  #
  #    SchemaPlus::ForeignKeys.setup do |config|
  #       ...
  #    end
  #
  class Config < Valuable


    ##
    # :attr_accessor: on_update
    #
    # The default value for +:on_update+ when creating foreign key
    # constraints for columns.  Valid values are as described in
    # ForeignKeyDefinition, or +nil+ to let the database connection use
    # its own default.  Default is +nil+.
    has_value :on_update

    ##
    # :attr_accessor: on_delete
    #
    # The default value for +:on_delete+ when creating foreign key
    # constraints for columns.  Valid values are as described in
    # ForeignKeyDefinition, or +nil+ to let the database connection use
    # its own default.  Default is +nil+.
    has_value :on_delete

    def merge(opts)
      dup.update_attributes(opts)
    end
  end


  # Returns the global configuration, i.e., the singleton instance of Config
  def self.config
    @config ||= Config.new
  end

  # Initialization block is passed a global Config instance that can be
  # used to configure SchemaPlus::ForeignKeys behavior.  E.g., put
  # something like the following in config/initializers/schema_plus_foreign_keys.rb :
  #
  #    SchemaPlus::ForeignKeys.setup do |config|
  #       config.on_update = :cascade
  #    end
  #
  def self.setup # :yields: config
    yield config
  end

end

SchemaMonkey.register SchemaPlus::ForeignKeys
