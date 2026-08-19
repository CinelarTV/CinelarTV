export default {
  path: "/community/:id(\\d+)/watch",
  name: "live.watch",
  component: () => import("../views/live-player"),
  meta: {
    requiresAuth: false,
    showHeader: false,
    title: "Watching Live",
  },
};
