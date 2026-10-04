import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "invest-tools-nav",

  initialize() {
    withPluginApi("1.0.0", (api) => {
      try {
        if (api.addCommunitySectionLink) {
          api.addCommunitySectionLink({
            name: "invest-watchlist",
            route: "invest.watchlist",
            title: "共同自选股",
            text: "⭐ 共同自选股",
          });
          api.addCommunitySectionLink({
            name: "invest-memos",
            route: "invest.memos",
            title: "我的备忘录",
            text: "📝 我的备忘录",
          });
        }
      } catch (e) {
        // eslint-disable-next-line no-console
        console.warn("invest-tools: addCommunitySectionLink unavailable", e);
      }
    });
  },
};
