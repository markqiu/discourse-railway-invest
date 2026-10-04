import Controller from "@ember/controller";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";

export default class InvestWatchlistController extends Controller {
  @tracked items = [];
  @tracked symbol = "";
  @tracked name = "";
  @tracked market = "A股";
  @tracked note = "";
  @tracked error = "";
  @tracked saving = false;

  markets = ["A股", "港股", "美股", "基金", "其他"];

  @action
  async reloadItems() {
    try {
      const data = await ajax("/invest/watchlist/items");
      this.items = data.items;
    } catch (e) {
      // 忽略加载错误（未登录跳转由后端处理）
    }
  }

  @action
  updateSymbol(e) {
    this.symbol = e.target.value;
  }

  @action
  updateName(e) {
    this.name = e.target.value;
  }

  @action
  updateMarket(e) {
    this.market = e.target.value;
  }

  @action
  updateNote(e) {
    this.note = e.target.value;
  }

  @action
  async addItem() {
    this.error = "";
    if (!this.symbol.trim() || !this.name.trim()) {
      this.error = "代码和名称不能为空";
      return;
    }
    this.saving = true;
    try {
      await ajax("/invest/watchlist/items", {
        type: "POST",
        data: {
          symbol: this.symbol,
          name: this.name,
          market: this.market,
          note: this.note,
        },
      });
      this.symbol = "";
      this.name = "";
      this.note = "";
      await this.reloadItems();
    } catch (e) {
      this.error = e?.jqXHR?.responseJSON?.errors?.join("；") || "添加失败";
    } finally {
      this.saving = false;
    }
  }

  @action
  async deleteItem(item) {
    if (!window.confirm(`确定把 ${item.name}（${item.symbol}）移出自选股？`)) {
      return;
    }
    await ajax(`/invest/watchlist/items/${item.id}`, { type: "DELETE" });
    await this.reloadItems();
  }
}
