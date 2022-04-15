module SchemaPlus
  module Core
    module ActiveRecord
      module ConnectionAdapters
        module AbstractAdapter
          module SchemaCreation

            def visit_ForeignKeyDefinition(o)
              # schema_plus_foreign_keys already implements a superior
              # conversion of ForeignKeyDefinitions to SQL
              o.to_sql
            end
          end
        end
      end
    end
  end
end
