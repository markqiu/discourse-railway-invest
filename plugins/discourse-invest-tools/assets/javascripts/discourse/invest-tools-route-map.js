export default function () {
  this.route("invest", function () {
    this.route("watchlist");
    this.route("memos");
  });
}
