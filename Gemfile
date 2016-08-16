source "http://rubygems.org"

gemspec

gem "schema_plus_core", git: "https://github.com/boazy/schema_plus_core.git", branch: "activerecord-5.0"

File.exist?(gemfile_local = File.expand_path('../Gemfile.local', __FILE__)) and eval File.read(gemfile_local), binding, gemfile_local
