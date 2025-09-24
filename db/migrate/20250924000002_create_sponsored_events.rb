# frozen_string_literal: true

class CreateSponsoredEvents < ActiveRecord::Migration[7.0]
  def change
    create_table :sponsored_events do |t|
      t.integer :sponsored_post_id, null: false
      t.string :event_type, null: false, limit: 20
      t.datetime :occurred_at, null: false
      t.timestamps null: false
    end
    
    add_index :sponsored_events, :sponsored_post_id
    add_index :sponsored_events, [:event_type, :occurred_at]
    add_index :sponsored_events, :occurred_at
    
    add_foreign_key :sponsored_events, :sponsored_posts, column: :sponsored_post_id, on_delete: :cascade
  end
end