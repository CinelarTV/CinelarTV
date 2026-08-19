export default {
  path: "/community/:id(\\d+)",
  name: "live.event",
  component: () => import("../views/live-event"),
  meta: {
    requiresAuth: false,
    title: "Live Event",
  },
};
