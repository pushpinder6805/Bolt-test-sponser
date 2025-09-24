# frozen_string_literal: true

class CreateSponsoredPosts < ActiveRecord::Migration[7.0]
  def change
    create_table :sponsored_posts do |t|
      t.integer :post_id, null: false
      t.integer :user_id, null: false
      t.datetime :starts_at, null: false
      t.datetime :expires_at, null: false
      t.boolean :active, default: false, null: false
      t.integer :impressions, default: 0, null: false
      t.integer :clicks, default: 0, null: false
      t.integer :likes, default: 0, null: false
      t.integer :replies, default: 0, null: false
      t.string :provider, limit: 50
      t.string :provider_payment_id, limit: 255
      t.timestamps null: false
    end
    
    add_index :sponsored_posts, :post_id
    add_index :sponsored_posts, :user_id
    add_index :sponsored_posts, [:active, :starts_at, :expires_at], name: 'index_sponsored_posts_active'
    add_index :sponsored_posts, :created_at
    
    add_foreign_key :sponsored_posts, :posts, column: :post_id, on_delete: :cascade
    add_foreign_key :sponsored_posts, :users, column: :user_id, on_delete: :cascade
  end
end