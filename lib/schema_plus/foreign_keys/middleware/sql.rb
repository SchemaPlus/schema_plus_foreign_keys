module SchemaPlus::ForeignKeys
  module Middleware
    module Sql
      module Table
        def after(env)
          foreign_keys = case 
                         when Gem::Requirement.new('~> 4.2.0').satisfied_by?(::ActiveRecord.version) then env.table_definition.foreign_keys
                         else env.table_definition.foreign_keys.values.tap { |v| v.flatten! }
                         end

          # create foreign key constraints inline in table definition
          env.sql.body = ([env.sql.body] + foreign_keys.map(&:to_sql)).join(', ')
 
          # prevents AR >= 4.2.1 from emitting add_foreign_key after the table
          env.table_definition.foreign_keys.clear
        end

        module SQLite3

          def before(env)
            env.connection.execute('PRAGMA FOREIGN_KEYS = ON') if env.table_definition.foreign_keys.any?
          end
        end
      end
    end
  end
end
