import Controller from "@ember/controller";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";

export default class InvestMemosController extends Controller {
  @tracked items = [];
  @tracked content = "";
  @tracked watchlistItemId = "";
  @tracked watchlistOptions = [];
  @tracked error = "";
  @tracked saving = false;

  @action
  async reloadItems() {
    try {
      const [memos, watchlist] = await Promise.all([
        ajax("/invest/memos/items"),
        ajax("/invest/watchlist/items"),
      ]);
      this.items = memos.items;
      this.watchlistOptions = watchlist.items;
    } catch (e) {
      // ignore
    }
  }

  @action
  updateContent(e) {
    this.content = e.target.value;
  }

  @action
  updateWatchlistItemId(e) {
    this.watchlistItemId = e.target.value;
  }

  @action
  async addMemo() {
    this.error = "";
    if (!this.content.trim()) {
      this.error = "内容不能为空";
      return;
    }
    this.saving = true;
    try {
      await ajax("/invest/memos/items", {
        type: "POST",
        data: {
          content: this.content,
          watchlist_item_id: this.watchlistItemId || null,
        },
      });
      this.content = "";
      await this.reloadItems();
    } catch (e) {
      this.error = e?.jqXHR?.responseJSON?.errors?.join("；") || "保存失败";
    } finally {
      this.saving = false;
    }
  }

  @action
  async toggleDone(memo) {
    await ajax(`/invest/memos/items/${memo.id}`, {
      type: "PUT",
      data: { done: !memo.done },
    });
    await this.reloadItems();
  }

  @action
  async deleteMemo(memo) {
    if (!window.confirm("确定删除这条备忘？")) {
      return;
    }
    await ajax(`/invest/memos/items/${memo.id}`, { type: "DELETE" });
    await this.reloadItems();
  }
}
