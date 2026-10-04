# frozen_string_literal: true

# name: discourse-invest-tools
# about: 小原同学AI投资俱乐部专用工具：社区共同自选股 + 个人备忘录
# version: 0.1.0
# authors: ata (markqiu)
# url: https://github.com/markqiu/discourse-railway-invest

enabled_site_setting :invest_tools_enabled

register_asset "stylesheets/invest-tools.scss"

module ::InvestTools
  PLUGIN_NAME = "discourse-invest-tools"
end

after_initialize do
  Discourse::Application.routes.append do
    # 页面（Ember 启动页）
    get "/invest/watchlist" => "invest_tools/watchlist#index"
    get "/invest/memos" => "invest_tools/memos#index"

    # JSON API
    get "/invest/watchlist/items" => "invest_tools/watchlist#items"
    post "/invest/watchlist/items" => "invest_tools/watchlist#create"
    delete "/invest/watchlist/items/:id" => "invest_tools/watchlist#destroy"

    get "/invest/memos/items" => "invest_tools/memos#items"
    post "/invest/memos/items" => "invest_tools/memos#create"
    put "/invest/memos/items/:id" => "invest_tools/memos#update"
    delete "/invest/memos/items/:id" => "invest_tools/memos#destroy"
  end
end
