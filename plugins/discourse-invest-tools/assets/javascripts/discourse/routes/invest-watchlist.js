import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";

export default class InvestWatchlistRoute extends DiscourseRoute {
  model() {
    return ajax("/invest/watchlist/items");
  }

  setupController(controller, model) {
    super.setupController(controller, model);
    controller.set("items", model?.items ?? []);
    controller.reloadItems();
  }
}
