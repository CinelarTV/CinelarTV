import { defineComponent, computed } from "vue";

export default defineComponent({
  name: "ActivityBadge",
  props: {
    activityScore: { type: Number, default: 0 },
    participantCount: { type: Number, default: 0 },
  },
  setup(props) {
    const level = computed(() => {
      if (props.participantCount >= 30 || props.activityScore >= 200) return "very_active";
      if (props.participantCount >= 10 || props.activityScore >= 50) return "active";
      if (props.participantCount >= 1) return "new";
      return "idle";
    });

    const label = computed(() => {
      switch (level.value) {
        case "very_active": return "Muy activa";
        case "active": return "Activa";
        case "new": return "Nueva";
        default: return "";
      }
    });

    const classes = computed(() => {
      switch (level.value) {
        case "very_active": return "bg-red-500/20 text-red-400";
        case "active": return "bg-orange-500/20 text-orange-400";
        case "new": return "bg-blue-500/20 text-blue-400";
        default: return "bg-white/10 text-white/60";
      }
    });

    return () =>
      label.value ? (
        <span
          class={`activity-badge inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium ${classes.value}`}
        >
          {level.value === "very_active" && <span class="live-indicator-pulse">&#x1F525;</span>}
          {level.value === "active" && <span>&#x1F525;</span>}
          {label.value}
        </span>
      ) : null;
  },
});
