require_relative 'abstract/schema_creation'

module SchemaPlus::ForeignKeys
  module ActiveRecord
    # SchemaPlus::ForeignKeys adds several methods to the connection adapter (as returned by ActiveRecordBase#connection).  See AbstractAdapter for details.
    module ConnectionAdapters

      #
      # SchemaPlus::ForeignKeys adds several methods to
      # ActiveRecord::ConnectionAdapters::AbstractAdapter.  In most cases
      # you don't call these directly, but rather the methods that define
      # things are called by schema statements, and methods that query
      # things are called by ActiveRecord::Base.
      #
      module AbstractAdapter

        # Define a foreign key constraint.  Valid options are :on_update,
        # :on_delete, and :deferrable, with values as described at
        # ConnectionAdapters::ForeignKeyDefinition
        #
        # (NOTE: Sqlite3 does not support altering a table to add foreign-key
        # constraints; they must be included in the table specification when
        # it's created.  If you're using Sqlite3, this method will raise an
        # error.)
        def add_foreign_key(from_table, to_table, **options) # (table_name, column, to_table, primary_key, options = {})
          options = options.dup
          options[:column] ||= foreign_key_column_for(to_table)

          foreign_key_sql = add_foreign_key_sql(from_table, to_table, options)
          execute "ALTER TABLE #{quote_table_name(from_table)} #{foreign_key_sql}"
        end

        # called directly by AT's bulk_change_table, for migration
        # change_table :name, bulk: true { ... }
        def add_foreign_key_sql(from_table, to_table, options = {}) #:nodoc:
          foreign_key = ::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(from_table, AbstractAdapter.proper_table_name(to_table), options)
          "ADD #{foreign_key.to_sql}"
        end

        def _build_foreign_key(from_table, to_table, options = {}) #:nodoc:
          ::ActiveRecord::ConnectionAdapters::ForeignKeyDefinition.new(from_table, AbstractAdapter.proper_table_name(to_table), options)
        end

        def self.proper_table_name(name)
          ::ActiveRecord::Migration.new.proper_table_name(name)
        end

        # Remove a foreign key constraint
        #
        # Arguments are the same as for add_foreign_key, or by name:
        #
        #    remove_foreign_key table_name, to_table, options
        #    remove_foreign_key table_name, name: constraint_name
        #
        # (NOTE: Sqlite3 does not support altering a table to remove
        # foreign-key constraints.  If you're using Sqlite3, this method will
        # raise an error.)
        def remove_foreign_key(from_table, to_table = nil, **options)
          options[:column] ||= foreign_key_column_for(to_table)
          if sql = remove_foreign_key_sql(from_table, to_table, options)
            execute "ALTER TABLE #{quote_table_name(from_table)} #{sql}"
          end
        end

        def get_foreign_key_name(from_table, to_table, options)
          return options[:name] if options[:name]

          fks = foreign_keys(from_table)
          if fks.detect { |it| it.name == to_table }
            ActiveSupport::Deprecation.warn "remove_foreign_key(table, name) is deprecated.  use remove_foreign_key(table, name: name)"
            return to_table
          end
          test_fk = _build_foreign_key(from_table, to_table, options)
          if fk = fks.detect { |fk| fk.match(test_fk) }
            fk.name
          else
            raise "SchemaPlus::ForeignKeys: no foreign key constraint found on #{from_table.inspect} matching #{[to_table, options].inspect}" unless options[:if_exists]
            nil
          end
        end

        def remove_foreign_key_sql(from_table, to_table, options)
          if foreign_key_name = get_foreign_key_name(from_table, to_table, options)
            "DROP CONSTRAINT #{options[:if_exists] ? "IF EXISTS" : ""} #{foreign_key_name}"
          end
        end


        #####################################################################
        #
        # The functions below here are abstract; each subclass should
        # define them all. Defining them here only for reference.
        #

        # (abstract) Return the ForeignKeyDefinition objects for foreign key
        # constraints defined on this table
        def foreign_keys(table_name, name = nil) raise "Internal Error: Connection adapter didn't override abstract function"; [] end

        # (abstract) Return the ForeignKeyDefinition objects for foreign key
        # constraints defined on other tables that reference this table
        def reverse_foreign_keys(table_name, name = nil) raise "Internal Error: Connection adapter didn't override abstract function"; [] end
      end
    end
  end
end
