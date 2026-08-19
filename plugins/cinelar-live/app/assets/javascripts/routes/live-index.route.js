export default {
  path: "/community",
  name: "live.index",
  component: () => import("../views/live-index"),
  meta: {
    requiresAuth: false,
    title: "CinelarTV Live",
  },
};
