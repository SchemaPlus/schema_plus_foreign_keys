# frozen_string_literal: true

module SchemaPlus::ForeignKeys
  module Middleware
    module Migration

      module CreateTable
        def around(env)
          if (original_block = env.block)
            config_options = env.options.delete(:foreign_keys) || {}
            env.block = -> (table_definition) {
              table_definition.schema_plus_foreign_keys_config = SchemaPlus::ForeignKeys.config.merge(config_options)
              original_block.call table_definition
            }
          end
          yield env
        end
      end

      module RenameTable
        def after(env)
          oldname = env.table_name
          newname = env.new_name
          env.connection.foreign_keys(newname).each do |fk|
            begin
              env.connection.remove_foreign_key(newname, name: fk.name)
              env.connection.add_foreign_key(newname, fk.to_table,
                                             column: fk.column,
                                             primary_key: fk.primary_key,
                                             name: fk.name.sub(/#{oldname}/, newname),
                                             on_update: fk.on_update,
                                             on_delete: fk.on_delete,
                                             deferrable: fk.deferrable)
            rescue NotImplementedError
              # sqlite3 can't remote or add foreign keys, so just skip it
            end
          end
        end
      end

      module Column

        #
        # Column option shortcuts
        #
        def before(env)
          opts = env.options[:foreign_key]

          return if opts == false

          opts = {} if opts == true

          [:references, :on_update, :on_delete, :deferrable].each do |key|
            (opts||={}).reverse_merge!(key => env.options[key]) if env.options.has_key? key
          end

          return if opts.nil?

          if opts.has_key?(:references) && !opts[:references]
            env.options[:foreign_key] = false
            return
          end

          case opts[:references]
          when nil
          when Array
            table, primary_key = opts[:references]
            opts[:references] = table
            opts[:primary_key] ||= primary_key
          end

          env.options[:foreign_key] = opts
        end

        #
        # Add the foreign keys
        #
        def around(env)
          original_options = env.options
          env.options = original_options.dup

          is_reference = (env.type == :reference)
          is_polymorphic = is_reference && env.options[:polymorphic]

          # usurp foreign key creation from AR, since it doesn't support
          # all our features
          env.options[:foreign_key] = false 

          yield env

          return if is_polymorphic or env.implements_reference

          env.options = original_options

          add_foreign_keys(env)

        end

        private

        def add_foreign_keys(env)

          if (reverting = env.caller.is_a?(::ActiveRecord::Migration::CommandRecorder) && env.caller.reverting)
            commands_length = env.caller.commands.length
          end

          config = (env.caller.try(:schema_plus_foreign_keys_config) || SchemaPlus::ForeignKeys.config)
          fk_opts = get_fk_opts(env, config)

          # remove existing fk in case of change of fk on existing column
          if env.operation == :change and fk_opts # includes :none for explicitly off
            remove_foreign_key_if_exists(env)
          end

          fk_opts = nil if fk_opts == :none

          create_fk(env, fk_opts) if fk_opts

          if reverting
            rev = []
            while env.caller.commands.length > commands_length
              cmd = env.caller.commands.pop
              rev.unshift cmd unless cmd[0].to_s =~ /^add_/
            end
            env.caller.commands.concat rev
          end

        end

        def create_fk(env, fk_opts)
          references = fk_opts.delete(:references)
          case env.caller
          when ::ActiveRecord::ConnectionAdapters::TableDefinition
            env.caller.foreign_key(references, **fk_opts)
          else
            env.caller.add_foreign_key(env.table_name, references, **fk_opts)
          end
        end

        def get_fk_opts(env, config)
          opts = env.options[:foreign_key]
          return nil if opts.nil?
          return :none if opts == false
          opts = {} if opts == true
          opts[:column] ||= env.column_name
          opts[:references] ||= default_table_name(env)
          opts[:on_update] ||= config.on_update
          opts[:on_delete] ||= config.on_delete
          opts
        end

        def remove_foreign_key_if_exists(env)
          env.caller.remove_foreign_key(env.table_name.to_s, column: env.column_name.to_s, if_exists: true)
        end

        def default_table_name(env)
          if env.column_name.to_s == 'parent_id'
            env.table_name
          else
            name = env.column_name.to_s.sub(/_id$/, '')
            name = name.pluralize if ::ActiveRecord::Base.pluralize_table_names
            name
          end
        end

      end

    end
  end
end
