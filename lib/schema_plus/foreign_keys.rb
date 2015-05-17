require 'schema_plus/core'

require_relative 'foreign_keys/version'

# Load any mixins to ActiveRecord modules, such as:
#
#require_relative 'foreign_keys/active_record/base'

# Load any middleware, such as:
#
# require_relative 'foreign_keys/middleware/model'

SchemaMonkey.register SchemaPlus::ForeignKeys
