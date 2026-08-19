import { defineComponent, onMounted, onUnmounted, ref } from "vue";
import { useRouter } from "vue-router";
import { useLiveService } from "../services/live-service";
import LiveSessionCard from "../components/LiveSessionCard";
import ScheduledEventCard from "../components/ScheduledEventCard";

export default defineComponent({
  name: "LiveIndex",
  setup() {
    const router = useRouter();
    const {
      activeSessions,
      upcomingEvents,
      loading,
      fetchEvents,
      attendEvent,
      unattendEvent,
    } = useLiveService();

    let messageBusHandler: ((data: any) => void) | null = null;

    onMounted(async () => {
      await fetchEvents();

      if (typeof window !== "undefined" && (window as any).MessageBus) {
        messageBusHandler = (data: any) => {
          if (data.type === "event_started" || data.type === "event_ended") {
            fetchEvents();
          }
        };
        (window as any).MessageBus.subscribe("/live/status", messageBusHandler);
      }
    });

    onUnmounted(() => {
      if (messageBusHandler && typeof window !== "undefined" && (window as any).MessageBus) {
        (window as any).MessageBus.unsubscribe("/live/status", messageBusHandler);
      }
    });

    const handleAttend = async (eventId: number) => {
      await attendEvent(eventId);
      router.push({ name: "live.event", params: { id: eventId } });
    };

    const handleUnattend = async (eventId: number) => {
      await unattendEvent(eventId);
    };

    return () => (
      <div class="min-h-screen bg-[#0a0a0f] text-white">
        <div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
          <div class="mb-8">
            <h1 class="text-3xl font-bold tracking-tight flex items-center gap-3">
              <span class="relative flex h-3 w-3">
                <span class="live-indicator-pulse absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75" />
                <span class="relative inline-flex rounded-full h-3 w-3 bg-red-500" />
              </span>
              CinelarTV Live
            </h1>
            <p class="mt-2 text-white/60">Películas que la comunidad está viendo ahora</p>
          </div>

          {loading.value ? (
            <div class="flex justify-center py-12">
              <div class="w-8 h-8 border-2 border-white/20 border-t-white rounded-full animate-spin" />
            </div>
          ) : (
            <>
              {activeSessions.value.length > 0 && (
                <section class="mb-10">
                  <h2 class="text-xl font-semibold mb-4 flex items-center gap-2">
                    <span class="text-red-400">&#x1F534;</span> Ahora
                  </h2>
                  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
                    {activeSessions.value.map((session) => (
                      <LiveSessionCard key={session.id} session={session} />
                    ))}
                  </div>
                </section>
              )}

              {upcomingEvents.value.length > 0 && (
                <section class="mb-10">
                  <h2 class="text-xl font-semibold mb-4 flex items-center gap-2">
                    <span>&#x1F4C5;</span> Próximamente
                  </h2>
                  <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                    {upcomingEvents.value.map((event) => (
                      <ScheduledEventCard
                        key={event.id}
                        event={event}
                        onAttend={handleAttend}
                        onUnattend={handleUnattend}
                      />
                    ))}
                  </div>
                </section>
              )}

              {activeSessions.value.length === 0 && upcomingEvents.value.length === 0 && (
                <div class="text-center py-16">
                  <svg
                    class="mx-auto w-16 h-16 text-white/20"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="1"
                      d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z"
                    />
                  </svg>
                  <h3 class="mt-4 text-lg font-medium text-white/80">No hay eventos activos</h3>
                  <p class="mt-2 text-sm text-white/50">
                    Vuelve más tarde para descubrir qué está viendo la comunidad.
                  </p>
                </div>
              )}
            </>
          )}
        </div>
      </div>
    );
  },
});
