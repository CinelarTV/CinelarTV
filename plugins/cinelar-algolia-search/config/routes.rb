# Plugin routes for Algolia Search
# The /search endpoint is patched via add_to_class, not routed here.

namespace :algolia, module: "algolia_search_plugin", path: "algolia", constraints: { format: :json } do
  get "config", to: "config#show"
end
