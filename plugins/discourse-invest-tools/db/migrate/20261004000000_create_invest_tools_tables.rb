# frozen_string_literal: true

class CreateInvestToolsTables < ActiveRecord::Migration[7.0]
  def up
    unless table_exists?(:invest_watchlist_items)
      create_table :invest_watchlist_items do |t|
        t.string :symbol, null: false, limit: 32
        t.string :name, null: false, limit: 64
        t.string :market, null: false, limit: 16
        t.text :note
        t.integer :created_by_id, null: false
        t.integer :category_id
        t.timestamps
      end
      add_index :invest_watchlist_items, %i[symbol market], unique: true
      add_index :invest_watchlist_items, :created_by_id
    end

    unless table_exists?(:invest_memos)
      create_table :invest_memos do |t|
        t.integer :user_id, null: false
        t.integer :invest_watchlist_item_id
        t.text :content, null: false
        t.boolean :done, null: false, default: false
        t.timestamps
      end
      add_index :invest_memos, :user_id
      add_index :invest_memos, :invest_watchlist_item_id
    end
  end

  def down
    drop_table :invest_memos if table_exists?(:invest_memos)
    drop_table :invest_watchlist_items if table_exists?(:invest_watchlist_items)
  end
end
