import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";

export default class InvestMemosRoute extends DiscourseRoute {
  model() {
    return ajax("/invest/memos/items");
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    controller.set("items", model?.items ?? []);
    controller.reloadItems();
  }
}
