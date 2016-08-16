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

            # The TableDefinition::foreign_keys attribute contains ForeignKeyDefinitions instead of
            # [to_table, options] tuples when using schema_plus_foreign_keys.
            # This function happily accepts to_table and options arguments anyway, so we just ignore
            # all arguments and treat to_table as the ForeignKeyDefinition and convert it to SQL
            # directly.
            def foreign_key_in_create(from_table, to_table, options)
              accept to_table # This is the ForeignKeyDefinition
            end

          end
        end
      end
    end
  end
end

