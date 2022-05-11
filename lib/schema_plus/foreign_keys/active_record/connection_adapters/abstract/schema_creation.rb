# frozen_string_literal: true

module SchemaPlus
  module Core
    module ActiveRecord
      module ConnectionAdapters
        if Gem::Version.new(::ActiveRecord::VERSION::STRING) < Gem::Version.new('6.1')
          module AbstractAdapter
            module SchemaCreation

              def visit_ForeignKeyDefinition(o)
                # schema_plus_foreign_keys already implements a superior
                # conversion of ForeignKeyDefinitions to SQL
                o.to_sql
              end
            end
          end
        else
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
