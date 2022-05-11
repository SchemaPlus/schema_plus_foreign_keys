[![Gem Version](https://badge.fury.io/rb/schema_plus_foreign_keys.svg)](http://badge.fury.io/rb/schema_plus_foreign_keys)
[![Build Status](https://github.com/SchemaPlus/schema_plus_foreign_keys/actions/workflows/prs.yml/badge.svg)](https://github.com/SchemaPlus/schema_plus_foreign_keys/actions)
[![Coverage Status](https://coveralls.io/repos/github/SchemaPlus/schema_plus_foreign_keys/badge.svg)](https://coveralls.io/github/SchemaPlus/schema_plus_foreign_keys)

# SchemaPlus::ForeignKeys

SchemaPlus::ForeignKeys provides extended support in ActiveRecord.  This includes extended support for declaring
foreign key constraints in migrations; support for deferrable constraints; support for SQLite3; cleaner schema dumps.

SchemaPlus::ForeignKeys is part of the [SchemaPlus](https://github.com/SchemaPlus/) family of Ruby on Rails ActiveRecord
extension gems.

For extra convenience, see also [schema_auto_foreign_keys](https://github.com/SchemaPlus/schema_auto_foreign_keys),
which creates foriegn key constraints automatically.


## Installation

<!-- SCHEMA_DEV: TEMPLATE INSTALLATION - begin -->
<!-- These lines are auto-inserted from a schema_dev template -->
As usual:

```ruby
gem "schema_plus_foreign_keys"                # in a Gemfile
gem.add_dependency "schema_plus_foreign_keys" # in a .gemspec
```

<!-- SCHEMA_DEV: TEMPLATE INSTALLATION - end -->

## Usage

### Migrations

To declare a foreign key constraint for a column, use the `:foreign_key`
option.  The same options can be used with `t.integer`, `t.references`, `t.belongs_to`, `t.foreign_key`,
`change_column`, and `add_foreign_key`:

    t.references :author, foreign_key: true           # create a foreign_key to table "authors"
    t.references :author, foreign_key: {}             # create a foreign_key to table "authors"
    t.references :author, foreign_key: false          # don't create a constraint (this is the default)
    t.integer :author,    foreign_key: true           # create a foreign_key to table "authors"

    t.references :parent, foreign_key: true           # special column parent_id defaults to referencing its own table

Specify the target table and its primary key using the `:references` and `:primary_key`:

    t.references :author, foreign_key: { references: :authors }        # the default
    t.integer :author,    foreign_key: { references: :authors }        # the default
    t.references :author, foreign_key: { references: :people }         # choose table name
    t.references :author, foreign_key: { primary_key: :ssn] }          # choose primary key
    t.references :author, foreign_key: { references: :people, primary_key: :ssn] } # choose both
    t.references :author, foreign_key: { references: [:people, :ssn] } # shortcut for both
    t.references :author, foreign_key: { references: nil }             # same as foreign_key: false

You can also specify other attributes that are supported by Rails:

    t.references :author, foreign_key: { name: "my_fk" }               # override default auto-generated constraint name
    t.references :author, foreign_key: { on_delete: :cascade }
    t.references :author, foreign_key: { on_update: :set_null }

In addition, support for deferrable constraints is implemented:

    t.references :author, foreign_key: { deferrable: true }
    t.references :author, foreign_key: { deferrable: :initially_deferred }

Of course the options can be combined:

    t.references :author, foreign_key: { references: :people, primary_key: :ssn, name: "my_fk", on_delet: :no_action }


As a shorthand, all options except `:name` can be specified without placing
them in a `foreign_key` hash, e.g.

    t.references :author, on_delete: :cascade  # shorthand for foreign_key: { on_delete: :cascade }
    t.references :author, references: :people  # shorthand for foreign_key: { references: :people }

To remove a foreign key constraint, you can either change the column, specifying `foreign_key: false`, or
use `migration.remove_foreign_key(table, column)`

### Introspection

To examine the foreign keys on a model, you can use:

    Model.foreign_keys            # foreign key constraints from this model to another
    Model.reverse_foreign_keys    # foreign key constraints from other models to this

(These results are cached along with other column-specific information; if you change the table definition, call `Model.reset_column_information` to clear the cache)

You can also query at the connection level (uncached):

    connection.foreign_keys(table_name)
    connection.reverse_foreign_keys(table_name)

These calls all return an array of ForeignKeyDefinition objects, which support these methods:

    fk.from_table
    fk.column
    fk.to_table
    fk.primary_key
    fk.on_update
    fk.on_delete
    fk.deferrable

### Configuring Defaults

If you don't specify `on_update` and `on_delete` when creating a foreign key
constraint, they normally default to whatever the DBMS's default behavior is.

But you can also configure a global default (e.g. in a Rails initializer):

```ruby
SchemaPlus::ForeignKeys.setup do |config|
    config.on_update = :cascade   # default is nil, meaning use default dbms behavior
    config.on_delete = :nullify   # default is nil, meaning use default dbms behavior
end
```

Or you can configure a per-table default in a migration:

```ruby
create_table :things, foreign_key: { on_update: :set_null } do |t|
    ...
end
```

### SQLite 3 Notes

SchemaPlus::ForeignKeys supports foreign key constraints in SQLite3. 

However note that SQLite3 requires you to declare the constraints as part of
the table definition, and does not allow you to add, remove, or change
constraints after the fact.  Thus you'll get an exception if you try
`add_foreign_key`, `remove_foreign_key`, or `change_column` changing the
foreign key options.


### Schema Dump

For clarity (and because it's required for SQLite3), in the generated `schema_dump.rb` file, the foreign key
definitions are included within the table definitions.

This means that the tables are output sorted that a table is
defined before others that depend on it.  If, however, there are circular dependencies in the
foreign key relations, this won't be possible; In that case some table definitions will include comments indicating
a "forward reference" to a table that's farther down in the file, and the constraint will be defined once that table
is defined (this can never happen with SQLite3).


## Compatibility

SchemaPlus::ForeignKeys is tested on:

<!-- SCHEMA_DEV: MATRIX - begin -->
<!-- These lines are auto-generated by schema_dev based on schema_dev.yml -->
* ruby **2.5** with activerecord **5.2**, using **mysql2**, **sqlite3** or **postgresql:9.6**
* ruby **2.5** with activerecord **6.0**, using **mysql2**, **sqlite3** or **postgresql:9.6**
* ruby **2.5** with activerecord **6.1**, using **mysql2**, **sqlite3** or **postgresql:9.6**
* ruby **2.7** with activerecord **5.2**, using **mysql2**, **sqlite3** or **postgresql:9.6**
* ruby **2.7** with activerecord **6.0**, using **mysql2**, **sqlite3** or **postgresql:9.6**
* ruby **2.7** with activerecord **6.1**, using **mysql2**, **sqlite3** or **postgresql:9.6**
* ruby **2.7** with activerecord **7.0**, using **mysql2**, **sqlite3** or **postgresql:9.6**
* ruby **3.0** with activerecord **6.0**, using **mysql2**, **sqlite3** or **postgresql:9.6**
* ruby **3.0** with activerecord **6.1**, using **mysql2**, **sqlite3** or **postgresql:9.6**
* ruby **3.0** with activerecord **7.0**, using **mysql2**, **sqlite3** or **postgresql:9.6**
* ruby **3.1** with activerecord **6.0**, using **mysql2**, **sqlite3** or **postgresql:9.6**
* ruby **3.1** with activerecord **6.1**, using **mysql2**, **sqlite3** or **postgresql:9.6**
* ruby **3.1** with activerecord **7.0**, using **mysql2**, **sqlite3** or **postgresql:9.6**

<!-- SCHEMA_DEV: MATRIX - end -->

## History

* 1.0.0 - Drop Ruby < 2.5 and Rails < 5.2, adding Rails 6.0, and remove many deprecations
* 0.1.8 - Compatibility with ActiveRecord 5.1 and ActiveRecord 5.2.
* 0.1.7 - Compatibility with ActiveRecord 5.0.
* 0.1.6 - Missing require
* 0.1.5 - Explicit gem dependencies
* 0.1.4 - Upgrade schema_plus_core dependency
* 0.1.3 - Support aciverecord 4.2.6.  Thanks to [@btsuhako](https://github.com/SchemaPlus/schema_plus_foreign_keys/issues?q=is%3Apr+is%3Aopen+author%3Abtsuhako) and [@dholdren](https://github.com/SchemaPlus/schema_plus_foreign_keys/issues?q=is%3Apr+is%3Aopen+author%3Adholdren)
* 0.1.2 - Handle very long names
* 0.1.1 - Cleanup; use (new) core Migration::RenameTable stack rather than monkey patching.
* 0.1.0 - Initial release, brought over from schema_plus 1.x via 2.0.0.pre*

## Development & Testing

Are you interested in contributing to SchemaPlus::ForeignKeys?  Thanks!  Please follow
the standard protocol: fork, feature branch, develop, push, and issue pull
request.

Some things to know about to help you develop and test:

<!-- SCHEMA_DEV: TEMPLATE USES SCHEMA_DEV - begin -->
<!-- These lines are auto-inserted from a schema_dev template -->
* **schema_dev**:  SchemaPlus::ForeignKeys uses [schema_dev](https://github.com/SchemaPlus/schema_dev) to
  facilitate running rspec tests on the matrix of ruby, activerecord, and database
  versions that the gem supports, both locally and on
  [github actions](https://github.com/SchemaPlus/schema_plus_foreign_keys/actions)

  To to run rspec locally on the full matrix, do:

        $ schema_dev bundle install
        $ schema_dev rspec

  You can also run on just one configuration at a time;  For info, see `schema_dev --help` or the [schema_dev](https://github.com/SchemaPlus/schema_dev) README.

  The matrix of configurations is specified in `schema_dev.yml` in
  the project root.

<!-- SCHEMA_DEV: TEMPLATE USES SCHEMA_DEV - end -->

<!-- SCHEMA_DEV: TEMPLATE USES SCHEMA_PLUS_CORE - begin -->
<!-- These lines are auto-inserted from a schema_dev template -->
* **schema_plus_core**: SchemaPlus::ForeignKeys uses the SchemaPlus::Core API that
  provides middleware callback stacks to make it easy to extend
  ActiveRecord's behavior.  If that API is missing something you need for
  your contribution, please head over to
  [schema_plus_core](https://github.com/SchemaPlus/schema_plus_core) and open
  an issue or pull request.

<!-- SCHEMA_DEV: TEMPLATE USES SCHEMA_PLUS_CORE - end -->

<!-- SCHEMA_DEV: TEMPLATE USES SCHEMA_MONKEY - begin -->
<!-- These lines are auto-inserted from a schema_dev template -->
* **schema_monkey**: SchemaPlus::ForeignKeys is implemented as a
  [schema_monkey](https://github.com/SchemaPlus/schema_monkey) client,
  using [schema_monkey](https://github.com/SchemaPlus/schema_monkey)'s
  convention-based protocols for extending ActiveRecord and using middleware stacks.

<!-- SCHEMA_DEV: TEMPLATE USES SCHEMA_MONKEY - end -->
