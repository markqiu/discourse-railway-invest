# frozen_string_literal: true

class InvestWatchlistItem < ActiveRecord::Base
  self.table_name = "invest_watchlist_items"

  MARKETS = %w[A股 港股 美股 基金 其他].freeze

  belongs_to :creator, class_name: "User", foreign_key: "created_by_id", optional: true
  belongs_to :category, optional: true
  has_many :invest_memos, dependent: :destroy

  validates :symbol, presence: true, length: { maximum: 32 }
  validates :name, presence: true, length: { maximum: 64 }
  validates :market, presence: true, inclusion: { in: MARKETS }
  validates :symbol, uniqueness: { scope: :market }

  def as_json_for(user)
    {
      id: id,
      symbol: symbol,
      name: name,
      market: market,
      note: note,
      category_id: category_id,
      created_by: creator&.username,
      created_at: created_at,
      can_delete: user.present? && (user.staff? || user.id == created_by_id),
      memo_count: invest_memos.count,
    }
  end
end
