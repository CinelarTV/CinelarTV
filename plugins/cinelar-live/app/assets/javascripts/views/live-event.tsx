import { defineComponent, onMounted, onUnmounted, computed } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useLiveService } from "../services/live-service";
import CountdownTimer from "../components/CountdownTimer";
import WaitingAttendees from "../components/WaitingAttendees";

export default defineComponent({
  name: "LiveEvent",
  setup() {
    const route = useRoute();
    const router = useRouter();
    const {
      currentEvent,
      loading,
      fetchEvent,
      attendEvent,
      unattendEvent,
    } = useLiveService();

    const eventId = computed(() => Number(route.params.id));
    let messageBusHandler: ((data: any) => void) | null = null;

    const poster = computed(() => currentEvent.value?.content?.poster);
    const title = computed(() => currentEvent.value?.title || currentEvent.value?.content?.title || "");
    const description = computed(() => currentEvent.value?.description);
    const startsAt = computed(() => {
      if (!currentEvent.value?.starts_at) return "";
      const d = new Date(currentEvent.value.starts_at);
      return d.toLocaleString("es-ES", {
        weekday: "long",
        hour: "2-digit",
        minute: "2-digit",
      });
    });
    const isLive = computed(() => currentEvent.value?.status === "live");
    const isScheduled = computed(() => currentEvent.value?.status === "scheduled");
    const isEnded = computed(() => currentEvent.value?.status === "ended");
    const isCancelled = computed(() => currentEvent.value?.status === "cancelled");

    onMounted(async () => {
      await fetchEvent(eventId.value);

      if (typeof window !== "undefined" && (window as any).MessageBus) {
        messageBusHandler = (data: any) => {
          if (data.type === "event_started" && data.event_id === eventId.value) {
            router.push({ name: "live.watch", params: { id: eventId.value } });
          }
          if (data.type === "attendee_count_changed" && currentEvent.value) {
            currentEvent.value.attendee_count = data.count;
          }
          if (data.type === "event_cancelled" && currentEvent.value) {
            currentEvent.value.status = "cancelled";
          }
        };
        (window as any).MessageBus.subscribe(`/live/event/${eventId.value}`, messageBusHandler);
      }
    });

    onUnmounted(() => {
      if (messageBusHandler && typeof window !== "undefined" && (window as any).MessageBus) {
        (window as any).MessageBus.unsubscribe(`/live/event/${eventId.value}`, messageBusHandler);
      }
    });

    const handleAttend = async () => {
      if (currentEvent.value?.is_attending) {
        await unattendEvent(eventId.value);
      } else {
        await attendEvent(eventId.value);
      }
    };

    const goToWatch = () => {
      router.push({ name: "live.watch", params: { id: eventId.value } });
    };

    return () => (
      <div class="min-h-screen bg-[#0a0a0f] text-white">
        <div class="mx-auto max-w-2xl px-4 py-8 sm:px-6">
          <button
            onClick={() => router.push({ name: "live.index" })}
            class="flex items-center gap-2 text-sm text-white/60 hover:text-white mb-6 transition-colors"
          >
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
            </svg>
            Volver
          </button>

          {loading.value ? (
            <div class="flex justify-center py-16">
              <div class="w-8 h-8 border-2 border-white/20 border-t-white rounded-full animate-spin" />
            </div>
          ) : currentEvent.value ? (
            <>
              <div class="flex justify-center mb-8">
                <div class="w-48 h-72 rounded-xl overflow-hidden bg-black/40 shadow-2xl">
                  {poster.value ? (
                    <img src={poster.value} alt={title.value} class="w-full h-full object-cover" />
                  ) : (
                    <div class="w-full h-full flex items-center justify-center">
                      <svg class="w-16 h-16 text-white/20" fill="none" viewBox="0 0 24 24" stroke="currentColor">
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
              </div>

              <h1 class="text-2xl font-bold text-center">{title.value}</h1>
              {description.value && (
                <p class="mt-2 text-center text-white/60 text-sm">{description.value}</p>
              )}

              <div class="mt-6 text-center">
                {isScheduled.value && (
                  <>
                    <p class="text-sm text-white/50 mb-2">{startsAt.value}</p>
                    <CountdownTimer targetDate={currentEvent.value.starts_at} />
                  </>
                )}
                {isLive.value && (
                  <span class="inline-flex items-center gap-2 text-red-400 font-semibold">
                    <span class="relative flex h-3 w-3">
                      <span class="live-indicator-pulse absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75" />
                      <span class="relative inline-flex rounded-full h-3 w-3 bg-red-500" />
                    </span>
                    EN DIRECTO
                  </span>
                )}
                {isEnded.value && <span class="text-white/40">Finalizada</span>}
                {isCancelled.value && <span class="text-white/40">Cancelada</span>}
              </div>

              <div class="mt-6 flex justify-center">
                <WaitingAttendees count={currentEvent.value.attendee_count} />
              </div>

              <div class="mt-8 flex flex-col gap-3">
                {isLive.value && (
                  <button
                    onClick={goToWatch}
                    class="w-full py-3 px-6 rounded-lg bg-red-500 text-white font-semibold hover:bg-red-600 transition-colors"
                  >
                    &#x1F534; VER EN DIRECTO
                  </button>
                )}
                {isScheduled.value && (
                  <button
                    onClick={handleAttend}
                    class={`w-full py-3 px-6 rounded-lg font-semibold transition-colors ${
                      currentEvent.value.is_attending
                        ? "bg-green-500/20 text-green-400 hover:bg-green-500/30"
                        : "bg-white/10 text-white hover:bg-white/20"
                    }`}
                  >
                    {currentEvent.value.is_attending ? "\u2713 En espera" : "Entrar en sala de espera"}
                  </button>
                )}
              </div>

              {currentEvent.value.organizer && (
                <div class="mt-6 text-center">
                  <p class="text-xs text-white/40">
                    Organizado por @{currentEvent.value.organizer.username}
                  </p>
                </div>
              )}
            </>
          ) : null}
        </div>
      </div>
    );
  },
});
