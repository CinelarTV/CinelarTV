import { defineComponent } from "vue";

export default defineComponent({
  name: "LiveIndicator",
  props: {
    size: { type: String, default: "md" },
  },
  setup(props) {
    const sizeClasses: Record<string, string> = {
      sm: "w-2 h-2",
      md: "w-3 h-3",
      lg: "w-4 h-4",
    };
    const cls = sizeClasses[props.size] || sizeClasses.md;

    return () => (
      <span class="inline-flex items-center gap-1.5">
        <span class={`relative flex ${cls}`}>
          <span class="live-indicator-pulse absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75" />
          <span class={`relative inline-flex rounded-full bg-red-500 ${cls}`} />
        </span>
        <span class="text-xs font-semibold text-red-400 uppercase tracking-wider">En directo</span>
      </span>
    );
  },
});
