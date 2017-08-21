require 'spec_helper'
require 'stringio'

describe "Schema dump" do

  before(:each) do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Schema.define do
        connection.tables_only.each do |table| drop_table table, force: :cascade end

        create_table :users, :force => true do |t|
          t.string :login
          t.datetime :deleted_at
          t.integer :first_post_id, index: { unique: true }
        end

        create_table :posts, :force => true do |t|
          t.text :body
          t.integer :user_id
          t.integer :first_comment_id
          t.string :string_no_default
          t.integer :short_id
          t.string :str_short
          t.integer :integer_col
          t.float :float_col
          t.decimal :decimal_col
          t.datetime :datetime_col
          t.timestamp :timestamp_col
          t.time :time_col
          t.date :date_col
          t.binary :binary_col
          t.boolean :boolean_col
        end

        create_table :comments, :force => true do |t|
          t.text :body
          t.integer :post_id
          t.integer :commenter_id
        end
      end
    end
    class ::User < ActiveRecord::Base ; end
    class ::Post < ActiveRecord::Base ; end
    class ::Comment < ActiveRecord::Base ; end
  end

  it "should enable foreign keys if any", sqlite3: :only do
    expect(dump_schema).to_not match(/PRAGMA FOREIGN_KEYS = ON/m)
    with_foreign_key Post, :user_id, :users, :id do
      expect(dump_schema).to match(/PRAGMA FOREIGN_KEYS = ON/m)
    end
  end

  it "should include foreign_key definition" do
    with_foreign_key Post, :user_id, :users, :id do
      expect(dump_posts).to match(%r{t.integer\s+"user_id".*foreign_key.*users})
    end
  end

  it "should include foreign_key name" do
    with_foreign_key Post, :user_id, :users, :id, :name => "yippee" do
      expect(dump_posts).to match(/user_id.*foreign_key.*users.*:name=>"yippee"/)
    end
  end

  it "should respect foreign key's primary key" do
    with_foreign_key Post, :user_id, :users, :first_post_id do
      expect(dump_posts).to match(%r{t.integer\s+"user_id".*foreign_key.*:primary_key=>"first_post_id"})
    end
  end


  it "should include foreign_key exactly once" do
    with_foreign_key Post, :user_id, :users, :id, :name => "yippee" do
      expect(dump_posts.scan(/foreign_key.*yippee"/).length).to eq 1
    end
  end


  xit "should sort foreign_key definitions" do
    with_foreign_keys Comment, [ [ :post_id, :posts, :id ], [ :commenter_id, :users, :id ]] do
      expect(dump_schema).to match(/foreign_key.+commenter_id.+foreign_key.+post_id/m)
    end
  end

  context "with constraint dependencies" do
    it "should sort in Posts => Comments direction" do
      with_foreign_key Comment, :post_id, :posts, :id do
        expect(dump_schema).to match(%r{create_table "posts".*create_table "comments"}m)
      end
    end
    it "should sort in Comments => Posts direction" do
      with_foreign_key Post, :first_comment_id, :comments, :id do
        expect(dump_schema).to match(%r{create_table "comments".*create_table "posts"}m)
      end
    end

    it "should handle regexp in ignore_tables" do
      with_foreign_key Comment, :post_id, :posts, :id do
        dump = dump_schema(:ignore => /post/)
        expect(dump).to match(/create_table "comments"/)
        expect(dump).not_to match(/create_table "posts"/)
      end
    end

  end

  it "should include foreign_key options" do
    with_foreign_key Post, :user_id, :users, :id, :on_update => :cascade, :on_delete => :nullify do
      expect(dump_posts).to match(%q[t.integer\s*"user_id",.*:foreign_key=>{:references=>"users", :name=>"fk_posts_user_id", :on_update=>:cascade, :on_delete=>:nullify}])
    end
  end

  context "with cyclic foreign key constraints", :sqlite3 => :skip do
    before(:each) do
      ActiveRecord::Base.connection.add_foreign_key(Comment.table_name, User.table_name, column: :commenter_id)
      ActiveRecord::Base.connection.add_foreign_key(Comment.table_name, Post.table_name, column: :post_id)
      ActiveRecord::Base.connection.add_foreign_key(Post.table_name, Comment.table_name, column: :first_comment_id)
      ActiveRecord::Base.connection.add_foreign_key(Post.table_name, User.table_name, column: :user_id)
      ActiveRecord::Base.connection.add_foreign_key(User.table_name, Post.table_name, column: :first_post_id)
    end

    it "should not raise an error" do
      expect { dump_schema }.to_not raise_error
    end

    ["comments", "posts", "users"].each do |table|
      it "should dump constraints for table #{table.inspect} after the table definition" do
        dump = dump_schema.gsub(/#[^\n*]/m, '')
        expect(dump =~ %r{create_table "#{table}"}).to be < (dump =~ %r{foreign_key.*"#{table}"})
      end
    end

    ["comments", "posts"].each do |table|
      qtable = table.inspect
      it "should dump comments for delayed constraint definition referencing table #{qtable}" do
        expect(dump_schema).to match(%r{# foreign key references #{qtable}.*create_table #{qtable}.*add_foreign_key \S+, #{qtable}}m)
      end
    end

    context 'with complicated schemas' do
      before(:each) do

        ActiveRecord::Migration.suppress_messages do
          ActiveRecord::Schema.define do
            connection.tables_only.each do |table| drop_table table, force: :cascade end

            create_table :grade_systems, force: true do |t|
              t.string   :name
              t.integer  :school_id
              t.integer  :parent_id
              t.integer  :profile_id
            end

            create_table :schools, force: true do |t|
              t.string   :name
              t.integer  :default_grade_system_id
            end

            create_table :academic_years, force: true do |t|
              t.string  :name
              t.integer :school_id
            end

            create_table :buildings, force: true do |t|
              t.string   :name
              t.integer  :school_id
            end

            create_table :profiles, force: true do |t|
              t.integer  :school_id
              t.integer  :building_id
            end

          end
        end

        class ::AcademicYear < ActiveRecord::Base ; end
        class ::Building < ActiveRecord::Base ; end
        class ::GradeSystem < ActiveRecord::Base ; end
        class ::Profile < ActiveRecord::Base ; end
        class ::School < ActiveRecord::Base ; end

        ActiveRecord::Base.connection.add_foreign_key(School.table_name, GradeSystem.table_name, column: :default_grade_system_id)
        ActiveRecord::Base.connection.add_foreign_key(GradeSystem.table_name, School.table_name, column: :school_id)
        ActiveRecord::Base.connection.add_foreign_key(GradeSystem.table_name, GradeSystem.table_name, column: :parent_id)
        ActiveRecord::Base.connection.add_foreign_key(GradeSystem.table_name, Profile.table_name, column: :profile_id)
        ActiveRecord::Base.connection.add_foreign_key(Profile.table_name, Building.table_name, column: :building_id)
        ActiveRecord::Base.connection.add_foreign_key(Profile.table_name, School.table_name, column: :school_id)
        ActiveRecord::Base.connection.add_foreign_key(Building.table_name, School.table_name, column: :school_id)
        ActiveRecord::Base.connection.add_foreign_key(AcademicYear.table_name, School.table_name, column: :school_id)
      end

      it "should not raise an error" do
        expect { dump_schema }.to_not raise_error
      end

      ["buildings", "grade_systems", "profiles", "schools"].each do |table|
        it "should dump constraints for table #{table.inspect} after the table definition" do
          expect(dump_schema =~ %r{create_table "#{table}"}).to be < (dump_schema =~ %r{foreign_key.*"#{table}"})
        end
      end
    end
  end

  protected
  def to_regexp(string)
    Regexp.new(Regexp.escape(string))
  end

  def with_foreign_key(model, columns, referenced_table_name, referenced_columns, options = {}, &block)
    with_foreign_keys(model, [[columns, referenced_table_name, referenced_columns, options]], &block)
  end

  def with_foreign_keys(model, columnsets)
    table_columns = model.columns.reject{|column| column.name == 'id'}
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table model.table_name, :force => true do |t|
        table_columns.each do |column|
          t.column column.name, column.type
        end
        columnsets.each do |columns, referenced_table_name, referenced_columns, options|
          t.foreign_key columns, referenced_table_name, (options||{}).merge(primary_key: referenced_columns)
        end
      end
    end
    model.reset_column_information
    begin
      yield
    ensure
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migration.create_table model.table_name, :force => true do |t|
          table_columns.each do |column|
            t.column column.name, column.type
          end
        end
      end
    end
  end

  def determine_foreign_key_name(model, columns, options)
    name = options[:name]
    name ||= model.foreign_keys.detect { |fk| fk.from_table == model.table_name.to_s && Array.wrap(fk.column) == Array.wrap(columns).collect(&:to_s) }.name
  end

  def dump_schema(opts={})
    stream = StringIO.new
    ActiveRecord::SchemaDumper.ignore_tables = Array.wrap(opts[:ignore]) || []
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
    stream.string
  end

  def dump_posts
    dump_schema(:ignore => %w[users comments])
  end

end
