import { defineComponent, computed } from "vue";
import { RouterLink } from "vue-router";
import type { LiveSession } from "../services/live-service";
import ActivityBadge from "./ActivityBadge";
import LiveIndicator from "./LiveIndicator";

export default defineComponent({
  name: "LiveSessionCard",
  props: {
    session: { type: Object as () => LiveSession, required: true },
  },
  setup(props) {
    const title = computed(() => props.session.content?.title || "Película sin título");
    const poster = computed(() => props.session.content?.poster);
    const participantCount = computed(() => props.session.participant_count);

    return () => (
      <RouterLink
        to={{ name: "live.watch", params: { id: props.session.id } }}
        class="group block rounded-xl overflow-hidden bg-white/5 border border-white/10 hover:border-white/20 transition-all duration-200 hover:scale-[1.02]"
      >
        <div class="relative aspect-video bg-black/40">
          {poster.value ? (
            <img src={poster.value} alt={title.value} class="w-full h-full object-cover" />
          ) : (
            <div class="w-full h-full flex items-center justify-center">
              <svg class="w-12 h-12 text-white/20" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="1.5"
                  d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"
                />
              </svg>
            </div>
          )}
          <div class="absolute top-2 right-2">
            <LiveIndicator size="sm" />
          </div>
        </div>
        <div class="p-3">
          <h3 class="text-sm font-semibold text-white truncate">{title.value}</h3>
          <div class="mt-1 flex items-center justify-between">
            <span class="text-xs text-white/60">{participantCount.value} viendo</span>
            <ActivityBadge
              activityScore={props.session.activity_score}
              participantCount={props.session.participant_count}
            />
          </div>
        </div>
      </RouterLink>
    );
  },
});
