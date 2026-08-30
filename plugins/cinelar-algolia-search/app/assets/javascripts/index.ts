import { definePlugin } from "@cinelartv/plugin-api";

export default definePlugin({
  id: "cinelar-algolia-search",
  setup(_api) {
    // The existing /search route is patched transparently
    // via ContentsController#search override in plugin.rb.
  },
});
