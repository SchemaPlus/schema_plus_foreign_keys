# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'schema_plus/foreign_keys/version'

Gem::Specification.new do |gem|
  gem.name          = "schema_plus_foreign_keys"
  gem.version       = SchemaPlus::ForeignKeys::VERSION
  gem.authors       = ["ronen barzel"]
  gem.email         = ["ronen@barzel.org"]
  gem.summary       = %q{Extended support for foreign key constraints in ActiveRecord}
  gem.description   = %q{Extended support for foreign key constraints in ActiveRecord, including: definition as column attribute; deferrable; and SQLite3 support; cleaner dumps; and more!}
  gem.homepage      = "https://github.com/SchemaPlus/schema_plus_foreign_keys"
  gem.license       = "MIT"

  gem.files         = `git ls-files -z`.split("\x0")
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "activerecord", ">= 4.2", "< 5.3"
  gem.add_dependency "schema_plus_core"
  gem.add_dependency "schema_plus_compatibility", "~> 0.2"
  gem.add_dependency "valuable"
  gem.add_dependency "its-it", "~> 1.2"

  gem.add_development_dependency "bundler", "~> 1.7"
  gem.add_development_dependency "rake", "~> 10.0"
  gem.add_development_dependency "rspec", "~> 3.0"
  gem.add_development_dependency "schema_dev", "~> 3.5"
  gem.add_development_dependency "simplecov"
  gem.add_development_dependency "simplecov-gem-profile"
end
