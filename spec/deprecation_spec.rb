require 'spec_helper'

describe 'Deprecations' do

  let(:migration) { ActiveRecord::Migration }

  describe "on add_foreign_key", sqlite3: :skip do
    before(:each) do
      define_schema do
        create_table :posts, id: :integer
        create_table :comments, id: :integer do |t|
          t.integer :post_id
        end
      end
      class Comment < ::ActiveRecord::Base ; end
    end

    it "deprecates 4-argument form" do
      expect(ActiveSupport::Deprecation).to receive(:warn).with(/4-argument/)
      migration.add_foreign_key "comments", "post_id", "posts", "id"
      expect(Comment).to reference(:posts, :id).on(:post_id)
    end

  end

  describe "on remove_foreign_key", sqlite3: :skip do
    before(:each) do
      define_schema do
        create_table :posts, id: :integer
        create_table :comments, id: :integer do |t|
          t.integer :post_id, foreign_key: true
        end
      end
      class Comment < ::ActiveRecord::Base ; end
    end

    it "deprecates :column_names option" do
      expect(ActiveSupport::Deprecation).to receive(:warn).with(/column_names/)
      migration.remove_foreign_key "comments", "posts", column_names: "post_id"
      Comment.reset_column_information
      expect(Comment).to_not reference(:posts, :id).on(:post_id)
    end

    it "deprecates :references_column_names option" do
      expect(ActiveSupport::Deprecation).to receive(:warn).with(/references_column_names.*primary_key/)
      migration.remove_foreign_key "comments", "posts", references_column_names: "id"
      Comment.reset_column_information
      expect(Comment).to_not reference(:posts, :id).on(:post_id)
    end

    it "deprecates :references_table_name option" do
      expect(ActiveSupport::Deprecation).to receive(:warn).with(/references_table_name.*to_table/)
      migration.remove_foreign_key "comments", references_table_name: "posts"
      Comment.reset_column_information
      expect(Comment).to_not reference(:posts, :id).on(:post_id)
    end

    it "deprecates table-and-name form" do
      Comment.reset_column_information
      name = Comment.foreign_keys.first.name
      expect(ActiveSupport::Deprecation).to receive(:warn).with(/name.*name: name/)
      migration.remove_foreign_key "comments", name
      Comment.reset_column_information
      expect(Comment).to_not reference(:posts, :id).on(:post_id)
    end

    it "deprecates 3-argument form" do
      expect(ActiveSupport::Deprecation).to receive(:warn).with(/3.*-argument/)
      migration.remove_foreign_key "comments", "post_id", "posts"
      Comment.reset_column_information
      expect(Comment).to_not reference(:posts, :id).on(:post_id)
    end

    it "deprecates 4-argument form" do
      expect(ActiveSupport::Deprecation).to receive(:warn).with(/4.*-argument/)
      migration.remove_foreign_key "comments", "post_id", "posts", "id"
      Comment.reset_column_information
      expect(Comment).to_not reference(:posts, :id).on(:post_id)
    end

    it "raises error for 5 arguments" do
      expect { migration.remove_foreign_key "zip", "a", "dee", "do", "da" }.to raise_error /Wrong number of arguments.*5/
    end

  end

  describe "on foreign key definition" do
    before(:each) do
      define_schema do
        create_table :posts, id: :integer
        create_table :comments, id: :integer do |t|
          t.integer :post_id, foreign_key: true
        end
      end
      class Comment < ::ActiveRecord::Base ; end
    end

    let(:definition) {
      Comment.reset_column_information
      Comment.foreign_keys.first
    }

    it "deprecates column_names" do
      expect(ActiveSupport::Deprecation).to receive(:warn).with(/column_names/)
      expect(definition.column_names).to eq(["post_id"])
    end

    it "deprecates references_column_names" do
      expect(ActiveSupport::Deprecation).to receive(:warn).with(/references_column_names.*primary_key/)
      expect(definition.references_column_names).to eq(["id"])
    end

    it "deprecates references_table_name" do
      expect(ActiveSupport::Deprecation).to receive(:warn).with(/references_table_name.*to_table/)
      expect(definition.references_table_name).to eq("posts")
    end

    it "deprecates table_name" do
      expect(ActiveSupport::Deprecation).to receive(:warn).with(/table_name.*from_table/)
      expect(definition.table_name).to eq("comments")
    end

    it "deprecates :set_null" do
      expect(ActiveSupport::Deprecation).to receive(:warn).with(/set_null.*nullify/)
      allow(ActiveSupport::Deprecation).to receive(:warn).with(/table_exists\? currently checks/)
      define_schema do
        create_table :posts, id: :integer
        create_table :comments, id: :integer do |t|
          t.integer :post_id, references: :posts, on_delete: :set_null
        end
      end
      expect(definition.on_delete).to eq(:nullify)
    end

  end

  describe "in table definition" do
    it "deprecates 3-column form" do
      expect(ActiveSupport::Deprecation).to receive(:warn).with(/positional arg.*primary_key/)
      allow(ActiveSupport::Deprecation).to receive(:warn).with(/table_exists\? currently checks/)
      define_schema do
        create_table :posts, id: :integer, primary_key: :funky
        create_table :comments, id: :integer do |t|
          t.integer :post_id
          t.foreign_key :post_id, :posts, :funky
        end
      end
      expect(migration.foreign_keys("comments").first.primary_key).to eq("funky")
    end

    it "raises error for 4 arguments" do
      expect {
        define_schema do
          create_table :posts, id: :integer, primary_key: :funky
          create_table :comments, id: :integer do |t|
            t.integer :post_id
            t.foreign_key :post_id, :posts, :funky, :town
          end
        end
      }.to raise_error /wrong number of arguments/i
    end
  end
end
