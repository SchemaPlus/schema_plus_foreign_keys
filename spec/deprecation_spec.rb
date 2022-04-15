require 'spec_helper'

describe 'Deprecations' do

  let(:migration) { ActiveRecord::Migration }

  describe "on foreign key definition" do
    before(:each) do
      define_schema do
        create_table :posts
        create_table :comments do |t|
          t.references :post, foreign_key: true
        end
      end
      class Comment < ::ActiveRecord::Base ; end
    end

    let(:definition) {
      Comment.reset_column_information
      Comment.foreign_keys.first
    }

    it "deprecates :set_null" do
      expect(ActiveSupport::Deprecation).to receive(:warn).with(/set_null.*nullify/)
      allow(ActiveSupport::Deprecation).to receive(:warn).with(/table_exists\? currently checks/)
      define_schema do
        create_table :posts
        create_table :comments do |t|
          t.references :post, references: :posts, on_delete: :set_null
        end
      end
      expect(definition.on_delete).to eq(:nullify)
    end

  end

  describe "in table definition" do
    it "raises error for 3 arguments" do
      expect {
        define_schema do
          create_table :posts, primary_key: :funky
          create_table :comments do |t|
            t.references :post
            t.foreign_key :post_id, :posts, :funky
          end
        end
      }.to raise_error /wrong number of arguments/i
    end

    it "raises error for 4 arguments" do
      expect {
        define_schema do
          create_table :posts, primary_key: :funky
          create_table :comments do |t|
            t.references :post
            t.foreign_key :post_id, :posts, :funky, :town
          end
        end
      }.to raise_error /wrong number of arguments/i
    end
  end
end
