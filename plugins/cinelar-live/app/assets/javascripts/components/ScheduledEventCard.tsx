import { defineComponent, computed } from "vue";
import type { LiveEvent } from "../services/live-service";
import CButton from "@/components/forms/c-button";
import CountdownTimer from "./CountdownTimer";
import WaitingAttendees from "./WaitingAttendees";

export default defineComponent({
  name: "ScheduledEventCard",
  props: {
    event: { type: Object as () => LiveEvent, required: true },
  },
  emits: ["attend", "unattend"],
  setup(props, { emit }) {
    const title = computed(() => props.event.title || props.event.content?.title || "Sin título");
    const poster = computed(() => props.event.content?.poster);
    const startDate = computed(() => {
      if (!props.event.starts_at) return "";
      const d = new Date(props.event.starts_at);
      return d.toLocaleDateString("es-ES", {
        weekday: "long",
        hour: "2-digit",
        minute: "2-digit",
      });
    });

    const isPast = computed(() => {
      if (!props.event.starts_at) return false;
      return new Date(props.event.starts_at).getTime() < Date.now();
    });

    const handleAttend = () => {
      if (props.event.is_attending) {
        emit("unattend", props.event.id);
      } else {
        emit("attend", props.event.id);
      }
    };

    return () => (
      <div class="rounded-xl overflow-hidden bg-white/5 border border-white/10">
        <div class="flex gap-4 p-4">
          <div class="w-20 h-28 flex-shrink-0 rounded-lg overflow-hidden bg-black/40">
            {poster.value ? (
              <img src={poster.value} alt={title.value} class="w-full h-full object-cover" />
            ) : (
              <div class="w-full h-full flex items-center justify-center">
                <svg class="w-8 h-8 text-white/20" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="1.5"
                    d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"
                  />
                </svg>
              </div>
            )}
          </div>
          <div class="flex-1 min-w-0">
            <h3 class="text-sm font-semibold text-white truncate">{title.value}</h3>
            <p class="mt-0.5 text-xs text-white/50">{startDate.value}</p>
            <div class="mt-2">
              <WaitingAttendees count={props.event.attendee_count} />
            </div>
            <div class="mt-2">
              {!isPast.value ? (
                <CountdownTimer targetDate={props.event.starts_at} showLabel={false} />
              ) : (
                <span class="text-xs text-red-400 font-medium">&#x1F534; En directo</span>
              )}
            </div>
          </div>
        </div>
        <div class="px-4 pb-4">
          <CButton
            onClick={handleAttend}
            class={`w-full py-2 px-4 rounded-lg text-sm font-medium transition-colors ${
              props.event.is_attending
                ? "bg-green-500/20 text-green-400 hover:bg-green-500/30"
                : "bg-white/10 text-white hover:bg-white/20"
            }`}
          >
            {props.event.is_attending ? "\u2713 En espera" : "Entrar en sala de espera"}
          </CButton>
        </div>
      </div>
    );
  },
});
