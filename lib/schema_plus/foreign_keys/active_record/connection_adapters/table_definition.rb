# frozen_string_literal: true

module SchemaPlus::ForeignKeys::ActiveRecord::ConnectionAdapters

  #
  # SchemaPlus::ForeignKeys adds several methods to TableDefinition, allowing indexes
  # and foreign key constraints to be defined within a
  # <tt>create_table</tt> block of a migration, allowing for better
  # encapsulation and more DRY definitions.
  #
  # For example, without SchemaPlus::ForeignKeys you might define a table like this:
  #
  #    create_table :widgets do |t|
  #       t.string :name
  #    end
  #    add_index :widgets, :name
  #
  # But with SchemaPlus::ForeignKeys, the index can be defined within the create_table
  # block, so you don't need to repeat the table name:
  #
  #    create_table :widgets do |t|
  #       t.string :name
  #       t.index :name
  #    end
  #
  # Even more DRY, you can define the index as part of the column
  # definition, via:
  #
  #   create_table :widgets do |t|
  #      t.string :name, index: true
  #   end
  #
  # For details about the :index option (including unique and multi-column indexes), see the
  # documentation for Migration::ClassMethods#add_column
  #
  # SchemaPlus::ForeignKeys also supports creation of foreign key constraints analogously, using Migration::ClassMethods#add_foreign_key or TableDefinition#foreign_key or as part of the column definition, for example:
  #
  #    create_table :posts do |t|  # not DRY
  #       t.references :author
  #    end
  #    add_foreign_key :posts, :author_id, references: :authors
  #
  #    create_table :posts do |t|  # DRYer
  #       t.references :author
  #       t.foreign_key :author_id, references: :authors
  #    end
  #
  #    create_table :posts do |t|  # Dryest
  #       t.references :author, foreign_key: true
  #    end
  #
  # <b>NOTE:</b> In the standard configuration, SchemaPlus::ForeignKeys automatically
  # creates foreign key constraints for columns whose names end in
  # <tt>_id</tt>.  So the above examples are redundant, unless automatic
  # creation was disabled at initialization in the global Config.
  #
  # SchemaPlus::ForeignKeys likewise by default automatically creates foreign key constraints for
  # columns defined via <tt>t.references</tt>.   However, SchemaPlus::ForeignKeys does not create
  # foreign key constraints if the <tt>:polymorphic</tt> option is true
  #
  # Finally, the configuration for foreign keys can be overriden on a per-table
  # basis by passing Config options to Migration::ClassMethods#create_table, such as
  #
  #      create_table :students, foreign_keys: {auto_create: false} do
  #         t.references :student
  #      end
  #
  module TableDefinition

    attr_accessor :schema_plus_foreign_keys_config #:nodoc:

  end
end
