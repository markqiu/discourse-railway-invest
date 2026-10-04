# frozen_string_literal: true

class ::InvestTools::MemosController < ::ApplicationController
  requires_login

  before_action :ensure_enabled

  # GET /invest/memos —— Ember 启动页
  def index
    render html: "", layout: "application"
  end

  # GET /invest/memos/items
  def items
    memos = InvestMemo.of_user(current_user).includes(:invest_watchlist_item).recent.limit(200)
    render_json_dump(items: memos.map { |m| m.as_json_for(current_user) })
  end

  # POST /invest/memos/items
  def create
    params.require(:content)
    memo =
      InvestMemo.new(
        user_id: current_user.id,
        content: params[:content].to_s.strip,
        invest_watchlist_item_id: params[:watchlist_item_id].presence,
      )
    if memo.save
      render_json_dump(memo.as_json_for(current_user))
    else
      render_json_error(memo)
    end
  end

  # PUT /invest/memos/items/:id
  def update
    memo = InvestMemo.of_user(current_user).find(params[:id])
    memo.content = params[:content].to_s.strip if params.key?(:content)
    memo.done = params[:done] if params.key?(:done)
    if memo.save
      render_json_dump(memo.as_json_for(current_user))
    else
      render_json_error(memo)
    end
  end

  # DELETE /invest/memos/items/:id
  def destroy
    InvestMemo.of_user(current_user).find(params[:id]).destroy!
    render json: success_json
  end

  private

  def ensure_enabled
    raise Discourse::NotFound unless SiteSetting.invest_tools_enabled
  end
end
