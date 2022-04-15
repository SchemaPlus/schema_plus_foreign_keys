module SchemaPlus::ForeignKeys
  module Middleware
    module Sql
      module Table
        module SQLite3
          def before(env)
            env.connection.execute('PRAGMA FOREIGN_KEYS = ON') if env.table_definition.foreign_keys.any?
          end
        end
      end
    end
  end
end
