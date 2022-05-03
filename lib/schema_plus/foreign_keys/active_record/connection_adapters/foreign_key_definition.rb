require 'active_record/connection_adapters/abstract/schema_definitions'

module SchemaPlus::ForeignKeys
  module ActiveRecord
    module ConnectionAdapters
      # Instances of this class are returned by the queries ActiveRecord::Base#foreign_keys and ActiveRecord::Base#reverse_foreign_keys (via AbstractAdapter#foreign_keys and AbstractAdapter#reverse_foreign_keys)
      #
      # The on_update and on_delete attributes can take on the following values:
      #   :cascade
      #   :restrict
      #   :nullify
      #   :set_default
      #   :no_action
      #
      # The deferrable attribute can take on the following values:
      #   true
      #   :initially_deferred
      module ForeignKeyDefinition
        ACTIONS = { cascade: "CASCADE", restrict: "RESTRICT", nullify: "SET NULL", set_default: "SET DEFAULT", no_action: "NO ACTION" }.freeze
        ACTION_LOOKUP = ACTIONS.invert.freeze

        def initialize(from_table, to_table, options={})
          [:on_update, :on_delete].each do |key|
            if options[key] == :set_null
              ActiveSupport::Deprecation.warn ":set_null value for #{key} is deprecated.  use :nullify instead"
              options[key] = :nullify
            end
          end

          super from_table, to_table, options

          if column.is_a?(Array) and column.length == 1
            options[:column] = column[0]
          end
          if primary_key.is_a?(Array) and primary_key.length == 1
            options[:primary_key] = primary_key[0]
          end

          ACTIONS.has_key?(on_update) or raise(ArgumentError, "invalid :on_update action: #{on_update.inspect}") if on_update
          ACTIONS.has_key?(on_delete) or raise(ArgumentError, "invalid :on_delete action: #{on_delete.inspect}") if on_delete
          if ::ActiveRecord::Base.connection.adapter_name =~ /^mysql/i
            raise(NotImplementedError, "MySQL does not support ON UPDATE SET DEFAULT") if on_update == :set_default
            raise(NotImplementedError, "MySQL does not support ON DELETE SET DEFAULT") if on_delete == :set_default
          end
        end

        # Truthy if the constraint is deferrable
        def deferrable
          options[:deferrable]
        end

        # Dumps a definition of foreign key.
        def to_dump
          opts = {column: self.column}.merge options_for_dump
          dump = "add_foreign_key #{from_table.inspect}, #{to_table.inspect}, #{opts.to_s.sub(/^{(.*)}$/, '\1')}"
        end

        def options_for_dump
          opts = {}
          opts[:primary_key] = self.primary_key if custom_primary_key?
          opts[:name] = name if name
          opts[:on_update] = on_update if on_update
          opts[:on_delete] = on_delete if on_delete
          opts[:deferrable] = deferrable if deferrable
          opts
        end

        def to_sql
          sql = name ? "CONSTRAINT #{name} " : ""
          sql << "FOREIGN KEY (#{quoted_column_names.join(", ")}) REFERENCES #{quoted_to_table} (#{quoted_primary_keys.join(", ")})"
          sql << " ON UPDATE #{ACTIONS[on_update]}" if on_update
          sql << " ON DELETE #{ACTIONS[on_delete]}" if on_delete
          sql << " DEFERRABLE" if deferrable
          sql << " INITIALLY DEFERRED" if deferrable == :initially_deferred
          sql
        end

        def quoted_column_names
          Array(column).map { |name| ::ActiveRecord::Base.connection.quote_column_name(name) }
        end

        def quoted_primary_keys
          Array(primary_key).map { |name| ::ActiveRecord::Base.connection.quote_column_name(name) }
        end

        def quoted_to_table
          ::ActiveRecord::Base.connection.quote_table_name(to_table)
        end

        def match(test)
          return false unless from_table == test.from_table
          [:to_table, :column].reject{ |attr| test.send(attr).blank? }.all? { |attr|
            test.send(attr).to_s == self.send(attr).to_s
          }
        end
      end
    end
  end
end
