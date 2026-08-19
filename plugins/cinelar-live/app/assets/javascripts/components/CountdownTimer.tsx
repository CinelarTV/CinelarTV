import { defineComponent, computed, ref, onMounted, onUnmounted } from "vue";

export default defineComponent({
  name: "CountdownTimer",
  props: {
    targetDate: { type: String, required: true },
    showLabel: { type: Boolean, default: true },
  },
  setup(props) {
    const now = ref(Date.now());
    let interval: ReturnType<typeof setInterval>;

    const diff = computed(() => {
      const target = new Date(props.targetDate).getTime() - now.value;
      return Math.max(0, target);
    });

    const hours = computed(() => Math.floor(diff.value / 3600000));
    const minutes = computed(() => Math.floor((diff.value % 3600000) / 60000));
    const seconds = computed(() => Math.floor((diff.value % 60000) / 1000));
    const isUrgent = computed(() => diff.value > 0 && diff.value < 300000);
    const isZero = computed(() => diff.value === 0);

    const formatted = computed(() => {
      const h = hours.value;
      const m = minutes.value;
      const s = seconds.value;
      if (h > 0) return `${h}h ${m}m`;
      if (m > 0) return `${m}m ${s}s`;
      return `${s}s`;
    });

    onMounted(() => {
      interval = setInterval(() => {
        now.value = Date.now();
      }, 1000);
    });

    onUnmounted(() => {
      clearInterval(interval);
    });

    return () => (
      <div class="countdown text-center">
        {isZero.value ? (
          <div class="text-lg font-bold text-green-400">Comenzando...</div>
        ) : (
          <div class="flex items-center gap-2 justify-center">
            {props.showLabel && (
              <span class="text-sm text-white/60">Comienza en</span>
            )}
            <span
              class={`countdown-digit text-2xl font-bold ${isUrgent.value ? "text-yellow-400" : "text-white"}`}
            >
              {formatted.value}
            </span>
          </div>
        )}
      </div>
    );
  },
});
