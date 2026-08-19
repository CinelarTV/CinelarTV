import { defineComponent, computed } from "vue";

export default defineComponent({
  name: "WaitingAttendees",
  props: {
    count: { type: Number, default: 0 },
  },
  setup(props) {
    const displayCount = computed(() => props.count);
    const showPlural = computed(() => props.count !== 1);

    return () => (
      <div class="flex items-center gap-2 text-white/70">
        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z"
          />
        </svg>
        <span class="text-sm font-medium">
          {displayCount.value} {showPlural.value ? "personas esperando" : "persona esperando"}
        </span>
      </div>
    );
  },
});
