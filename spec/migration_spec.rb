# encoding: utf-8
require 'spec_helper'

describe ActiveRecord::Migration do

  before(:each) do
    define_schema do

      create_table :users, :force => true do |t|
        t.string :login, :index => { :unique => true }
      end

      create_table :members, :force => true do |t|
        t.string :login
      end

      create_table :comments, :force => true do |t|
        t.string :content
        t.integer :user
        t.integer :user_id
        t.foreign_key :user_id, :users, :primary_key => :id
      end

      create_table :posts, :force => true do |t|
        t.string :content
      end
    end
    class User < ::ActiveRecord::Base ; end
    class Post < ::ActiveRecord::Base ; end
    class Comment < ::ActiveRecord::Base ; end
  end

  context "when table is created" do

    before(:each) do
      @model = Post
    end

    it "should enable foreign keys", :sqlite3 => :only do
      sql = []
      allow(@model.connection).to receive(:execute) { |str| sql << str }
      recreate_table(@model) do |t|
        t.integer :user, :foreign_key => true
      end
      expect(sql.join('; ')).to match(/PRAGMA FOREIGN_KEYS = ON.*CREATE TABLE "posts"/)
    end

    it "should create foreign key with default reference" do
      recreate_table(@model) do |t|
        t.integer :user, :foreign_key => true
      end
      expect(@model).to reference(:users, :id).on(:user)
    end

    it "should create foreign key with default column" do
      recreate_table(@model) do |t|
        t.integer :user_id
        t.foreign_key :users
      end
      expect(@model).to reference(:users, :id).on(:user_id)
    end

    it "should create foreign key with different reference" do
      recreate_table(@model) do |t|
        t.integer :author_id, :foreign_key => { :references => :users }
      end
      expect(@model).to reference(:users, :id).on(:author_id)
    end

    it "should create foreign key without modifying input hash" do
      hash = { :references => :users }
      hash_original = hash.dup
      recreate_table(@model) do |t|
        t.integer :author_id, :foreign_key => hash
      end
      expect(hash).to eq(hash_original)
    end

    it "should create foreign key without modifying input hash" do
      hash = { :references => :users }
      hash_original = hash.dup
      recreate_table(@model) do |t|
        t.references :author, :type => :integer, :foreign_key => hash
      end
      expect(hash).to eq(hash_original)
    end

    it "should create foreign key with different reference using shortcut" do
      recreate_table(@model) do |t|
        t.integer :author_id, :references => :users
      end
      expect(@model).to reference(:users, :id).on(:author_id)
    end

    it "should create foreign key with default name" do
      recreate_table @model do |t|
        t.integer :user_id, :foreign_key => true
      end
      expect(@model).to reference(:users, :id).with_name("fk_#{@model.table_name}_user_id")
    end

    it "should create foreign key with specified name" do
      recreate_table @model do |t|
        t.integer :user_id, :foreign_key => { :name => "wugga" }
      end
      expect(@model).to reference(:users, :id).with_name("wugga")
    end

    it "handles very long names" do
      table = ("ta"*15)
      column = ("co"*15 + "_id")
      expect {
        ActiveRecord::Migration.create_table table do |t|
          t.integer column, references: :members
        end
      }.not_to raise_error
      expect(ActiveRecord::Base.connection.foreign_keys(table).first.column).to eq(column)
    end

    it "should allow multiple foreign keys to be made" do
      recreate_table(@model) do |t|
        t.integer :user_id, :references => :users
        t.integer :updater_id, :references => :users
      end
      expect(@model).to reference(:users, :id).on(:user_id)
      expect(@model).to reference(:users, :id).on(:updater_id)
    end

    it "should suppress foreign key" do
      recreate_table(@model) do |t|
        t.integer :member_id, :foreign_key => false
      end
      expect(@model).not_to reference.on(:member_id)
    end

    it "should suppress foreign key using shortcut" do
      recreate_table(@model) do |t|
        t.integer :member_id, :references => nil
      end
      expect(@model).not_to reference.on(:member_id)
    end

    it "should create foreign key using t.belongs_to" do
      recreate_table(@model) do |t|
        t.belongs_to :user, :type => :integer, :foreign_key => true
      end
      expect(@model).to reference(:users, :id).on(:user_id)
    end

    it "should not create foreign key using t.belongs_to with :polymorphic => true" do
      recreate_table(@model) do |t|
        t.belongs_to :user, :type => :integer, :polymorphic => true
      end
      expect(@model).not_to reference(:users, :id).on(:user_id)
    end

    it "should create foreign key using t.references" do
      recreate_table(@model) do |t|
        t.references :user, :type => :integer, :foreign_key => true
      end
      expect(@model).to reference(:users, :id).on(:user_id)
    end

    it "should not create foreign key using t.references with :foreign_key => false" do
      recreate_table(@model) do |t|
        t.references :user, :type => :integer, :foreign_key => false
      end
      expect(@model).not_to reference(:users, :id).on(:user_id)
    end

    it "should not create foreign key using t.references with :polymorphic => true" do
      recreate_table(@model) do |t|
        t.references :user, :type => :integer, :polymorphic => true
      end
      expect(@model).not_to reference(:users, :id).on(:user_id)
    end

    it "should create foreign key to the same table on parent_id" do
      recreate_table(@model) do |t|
        t.integer :parent_id, foreign_key: true
      end
      expect(@model).to reference(@model.table_name, :id).on(:parent_id)
    end

    actions = [:cascade, :restrict, :nullify, :set_default, :no_action]

    actions.each do |action|
      if action == :set_default
        if_action_supported = { :mysql => :skip }
        if_action_unsupported = { :mysql => :only }
      else
        if_action_supported = { :if => true }
        if_action_unsupported = { :if => false }
      end

      it "should create and detect on_update #{action.inspect}", if_action_supported do
        recreate_table @model do |t|
          t.integer :user_id,   :foreign_key => { :on_update => action }
        end
        expect(@model).to reference.on(:user_id).on_update(action)
      end

      it "should create and detect on_update #{action.inspect} using shortcut", if_action_supported do
        recreate_table @model do |t|
          t.integer :user_id,   :on_update => action
        end
        expect(@model).to reference.on(:user_id).on_update(action)
      end

      it "should raise a not-implemented error for on_update => #{action}", if_action_unsupported do
        expect {
          recreate_table @model do |t|
            t.integer :user_id, :foreign_key => { :on_update => action }
          end
        }.to raise_error(NotImplementedError)
      end

      it "should create and detect on_delete #{action.inspect}", if_action_supported do
        recreate_table @model do |t|
          t.integer :user_id,   :foreign_key => { :on_delete => action }
        end
        expect(@model).to reference.on(:user_id).on_delete(action)
      end

      it "should create and detect on_delete #{action.inspect} using shortcut", if_action_supported do
        recreate_table @model do |t|
          t.integer :user_id,   :on_delete => action
        end
        expect(@model).to reference.on(:user_id).on_delete(action)
      end

      it "should raise a not-implemented error for on_delete => #{action}", if_action_unsupported do
        expect {
          recreate_table @model do |t|
            t.integer :user_id, :foreign_key => { :on_delete => action }
          end
        }.to raise_error(NotImplementedError)
      end

    end

    [false, true, :initially_deferred].each do |status|
      it "should create and detect deferrable #{status.inspect}", :mysql => :skip do
        recreate_table @model do |t|
          t.integer :user_id,   :on_delete => :cascade, :deferrable => status
        end
        expect(@model).to reference.on(:user_id).deferrable(status)
      end
    end

    it "should use default on_delete action" do
      with_fk_config(:on_delete => :cascade) do
        recreate_table @model do |t|
          t.integer :user_id, foreign_key: true
        end
        expect(@model).to reference.on(:user_id).on_delete(:cascade)
      end
    end

    it "should override on_update action per table" do
      with_fk_config(:on_update => :cascade) do
        recreate_table @model, :foreign_keys => {:on_update => :restrict} do |t|
          t.integer :user_id, foreign_key: true
        end
        expect(@model).to reference.on(:user_id).on_update(:restrict)
      end
    end

    it "should override on_delete action per table" do
      with_fk_config(:on_delete => :cascade) do
        recreate_table @model, :foreign_keys => {:on_delete => :restrict} do |t|
          t.integer :user_id, foreign_key: true
        end
        expect(@model).to reference.on(:user_id).on_delete(:restrict)
      end
    end

    it "should override on_update action per column" do
      with_fk_config(:on_update => :cascade) do
        recreate_table @model, :foreign_keys => {:on_update => :restrict} do |t|
          t.integer :user_id, :foreign_key => { :on_update => :nullify }
        end
        expect(@model).to reference.on(:user_id).on_update(:nullify)
      end
    end

    it "should override on_delete action per column" do
      with_fk_config(:on_delete => :cascade) do
        recreate_table @model, :foreign_keys => {:on_delete => :restrict} do |t|
          t.integer :user_id, :foreign_key => { :on_delete => :nullify }
        end
        expect(@model).to reference.on(:user_id).on_delete(:nullify)
      end
    end

    it "should raise an error for an invalid on_update action" do
      expect {
        recreate_table @model do |t|
          t.integer :user_id, :foreign_key => { :on_update => :invalid }
        end
      }.to raise_error(ArgumentError)
    end

    it "should raise an error for an invalid on_delete action" do
      expect {
        recreate_table @model do |t|
          t.integer :user_id, :foreign_key => { :on_delete => :invalid }
        end
      }.to raise_error(ArgumentError)
    end

  end

  context "when table is changed" do
    before(:each) do
      @model = Post
    end
    [false, true].each do |bulk|
      suffix = bulk ? ' with :bulk option' : ""

      it "should create a foreign key constraint"+suffix, :sqlite3 => :skip do
        change_table(@model, :bulk => bulk) do |t|
          t.integer :user_id, foreign_key: true
        end
        expect(@model).to reference(:users, :id).on(:user_id)
      end

      context "migrate down" do
        it "should remove a foreign key constraint"+suffix, :sqlite3 => :skip do
          Comment.reset_column_information
          expect(Comment).to reference(:users, :id).on(:user_id)
          migration = Class.new ::ActiveRecord::Migration.latest_version do
            define_method(:change) {
              change_table("comments", :bulk => bulk) do |t|
                t.integer :user_id, foreign_key: true
              end
            }
          end
          ActiveRecord::Migration.suppress_messages do
            migration.migrate(:down)
          end
          Comment.reset_column_information
          expect(Comment).not_to reference(:users, :id).on(:user_id)
        end
      end

      it "should create a foreign key constraint using :references"+suffix, :sqlite3 => :skip do
        change_table(@model, :bulk => bulk) do |t|
          t.references :user, type: :integer, foreign_key: true
        end
        expect(@model).to reference(:users, :id).on(:user_id)
      end

      it "should create a foreign key constraint using :belongs_to"+suffix, :sqlite3 => :skip do
        change_table(@model, :bulk => bulk) do |t|
          t.belongs_to :user, type: :integer, foreign_key: true
        end
        expect(@model).to reference(:users, :id).on(:user_id)
      end
    end
  end

  context "when column is added", :sqlite3 => :skip do

    before(:each) do
      @model = Comment
    end

    it "should create foreign key" do
      add_column(:post_id, :integer, foreign_key: true) do
        expect(@model).to reference(:posts, :id).on(:post_id)
      end
    end

    it "should create foreign key to explicitly given table" do
      add_column(:author_id, :integer, :foreign_key => { :references => :users }) do
        expect(@model).to reference(:users, :id).on(:author_id)
      end
    end

    it "should create foreign key to explicitly given table using shortcut" do
      add_column(:author_id, :integer, :references => :users) do
        expect(@model).to reference(:users, :id).on(:author_id)
      end
    end

    it "should create foreign key to explicitly given table and column name" do
      add_column(:author_login, :string, :foreign_key => { :references => [:users, :login]}) do
        expect(@model).to reference(:users, :login).on(:author_login)
      end
    end

    it "should create foreign key to the same table on parent_id" do
      add_column(:parent_id, :integer, foreign_key: true) do
        expect(@model).to reference(@model.table_name, :id).on(:parent_id)
      end
    end

    it "should use default on_update action" do
      SchemaPlus::ForeignKeys.config.on_update = :cascade
      add_column(:post_id, :integer, foreign_key: true) do
        expect(@model).to reference.on(:post_id).on_update(:cascade)
      end
      SchemaPlus::ForeignKeys.config.on_update = nil
    end

    it "should use default on_delete action" do
      SchemaPlus::ForeignKeys.config.on_delete = :cascade
      add_column(:post_id, :integer, foreign_key: true) do
        expect(@model).to reference.on(:post_id).on_delete(:cascade)
      end
      SchemaPlus::ForeignKeys.config.on_delete = nil
    end

    it "should allow to overwrite default actions" do
      SchemaPlus::ForeignKeys.config.on_delete = :cascade
      SchemaPlus::ForeignKeys.config.on_update = :restrict
      add_column(:post_id, :integer, :foreign_key => { :on_update => :nullify, :on_delete => :nullify}) do
        expect(@model).to reference.on(:post_id).on_delete(:nullify).on_update(:nullify)
      end
      SchemaPlus::ForeignKeys.config.on_delete = nil
    end

    it "should create foreign key with default name" do
      add_column(:post_id, :integer, foreign_key: true) do
        expect(@model).to reference(:posts, :id).with_name("fk_#{@model.table_name}_post_id")
      end
    end

    protected
    def add_column(column_name, *args)
      table = @model.table_name
      ActiveRecord::Migration.add_column(table, column_name, *args)
      @model.reset_column_information
      yield if block_given?
      ActiveRecord::Migration.remove_column(table, column_name)
    end

  end


  context "when column is changed" do

    before(:each) do
      @model = Comment
    end

    context "with foreign keys", :sqlite3 => :skip do

      it "should create foreign key" do
        change_column :user, :string, :foreign_key => { :references => [:users, :login] }
        expect(@model).to reference(:users, :login).on(:user)
      end

      context "and initially references to users table" do

        before(:each) do
          recreate_table @model do |t|
            t.integer :user_id, foreign_key: true
          end
        end

        it "should have foreign key" do
          expect(@model).to reference(:users)
        end

        it "should drop foreign key if it is no longer valid" do
          change_column :user_id, :integer, :foreign_key => { :references => :members }
          expect(@model).not_to reference(:users)
        end

        it "should drop foreign key if requested to do so" do
          change_column :user_id, :integer, :foreign_key => { :references => nil }
          expect(@model).not_to reference(:users)
        end

        it "should reference pointed table afterwards if new one is created" do
          change_column :user_id, :integer, :foreign_key => { :references => :members }
          expect(@model).to reference(:members)
        end

        it "should maintain foreign key if it's unaffected by change" do
          change_column :user_id, :integer, :default => 0
          expect(@model).to reference(:users)
        end

      end

    end

    protected
    def change_column(column_name, *args)
      table = @model.table_name
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migration.change_column(table, column_name, *args)
        @model.reset_column_information
      end
    end

  end

  context "when column is removed", :sqlite3 => :skip do
    before(:each) do
      @model = Comment
      recreate_table @model do |t|
        t.integer :post_id, foreign_key: true
      end
    end

    it "should remove a foreign key" do
      expect(@model).to reference(:posts)
      remove_column(:post_id)
      expect(@model).not_to reference(:posts)
    end

    protected
    def remove_column(column_name)
      table = @model.table_name
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migration.remove_column(table, column_name)
        @model.reset_column_information
      end
    end
  end


  context "when table is renamed" do

    before(:each) do
      @model = Comment
      recreate_table @model do |t|
        t.integer :user_id, foreign_key: true
        t.integer :xyz, :index => true
      end
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migration.rename_table @model.table_name, :newname
      end
    end

    it "should rename foreign key constraints", :sqlite3 => :skip do
      expect(ActiveRecord::Base.connection.foreign_keys(:newname).first.name).to match(/newname/)
    end

  end


  context "when table with more than one fk constraint is renamed", :sqlite3 => :skip do

    before(:each) do
      @model = Comment
      recreate_table @model do |t|
        t.integer :user_id
        t.integer :member_id
      end
      ActiveRecord::Migration.suppress_messages do
        ActiveRecord::Migration.rename_table @model.table_name, :newname
      end
    end

    it "should rename foreign key constraints" do
      names = ActiveRecord::Base.connection.foreign_keys(:newname).map(&:name)
      expect(names.grep(/newname/)).to eq(names)
    end
  end

  def recreate_table(model, opts={}, &block)
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.create_table model.table_name, opts.merge(:force => true), &block
    end
    model.reset_column_information
  end

  def change_table(model, opts={}, &block)
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Migration.change_table model.table_name, opts, &block
    end
    model.reset_column_information
  end

end

