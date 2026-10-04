# frozen_string_literal: true

class ::InvestTools::WatchlistController < ::ApplicationController
  requires_login

  before_action :ensure_enabled

  # GET /invest/watchlist —— Ember 启动页
  def index
    render html: "", layout: "application"
  end

  # GET /invest/watchlist/items
  def items
    items = InvestWatchlistItem.includes(:creator, :invest_memos).order(created_at: :desc)
    render_json_dump(items: items.map { |i| i.as_json_for(current_user) })
  end

  # POST /invest/watchlist/items
  def create
    params.require(%i[symbol name market])
    item =
      InvestWatchlistItem.new(
        symbol: params[:symbol].to_s.strip,
        name: params[:name].to_s.strip,
        market: params[:market].to_s.strip,
        note: params[:note].to_s.strip.presence,
        created_by_id: current_user.id,
      )
    if item.save
      render_json_dump(item.as_json_for(current_user))
    else
      render_json_error(item)
    end
  end

  # DELETE /invest/watchlist/items/:id
  def destroy
    item = InvestWatchlistItem.find(params[:id])
    guardian.ensure_can_delete!(item) if item.created_by_id != current_user.id && !current_user.staff?
    raise Discourse::InvalidAccess unless current_user.staff? || item.created_by_id == current_user.id
    item.destroy!
    render json: success_json
  end

  private

  def ensure_enabled
    raise Discourse::NotFound unless SiteSetting.invest_tools_enabled
  end
end
