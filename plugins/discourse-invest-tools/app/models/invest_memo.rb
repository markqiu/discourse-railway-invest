# frozen_string_literal: true

class InvestMemo < ActiveRecord::Base
  self.table_name = "invest_memos"

  belongs_to :user
  belongs_to :invest_watchlist_item, optional: true

  validates :content, presence: true, length: { maximum: 2000 }

  scope :of_user, ->(user) { where(user_id: user.id) }
  scope :recent, -> { order(updated_at: :desc) }

  def as_json_for(_user)
    {
      id: id,
      content: content,
      done: done,
      watchlist_item_id: invest_watchlist_item_id,
      symbol: invest_watchlist_item&.symbol,
      item_name: invest_watchlist_item&.name,
      created_at: created_at,
      updated_at: updated_at,
    }
  end
end
