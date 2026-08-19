import { defineComponent, onMounted, onUnmounted, ref, computed } from "vue";
import { useRoute, useRouter } from "vue-router";
import { createLiveSyncHandler } from "../services/live-sync-handler";
import { useCurrentUser } from "@/app/services/current-user";
import CButton from "@/components/forms/c-button";
import CSpinner from "@/components/c-spinner";
import LiveIndicator from "../components/LiveIndicator";
import CountdownTimer from "../components/CountdownTimer";
import LiveChat from "../components/LiveChat";
import LiveReactions from "../components/LiveReactions";

export default defineComponent({
  name: "LivePlayer",
  setup() {
    const route = useRoute();
    const router = useRouter();
    const videoRef = ref<HTMLVideoElement | null>(null);
    const playerContainerRef = ref<HTMLDivElement | null>(null);
    const isControlsVisible = ref(true);
    const buffering = ref(false);
    const contentTitle = ref("");
    const eventStatus = ref("");
    const startsAt = ref("");
    const poster = ref("");
    const isOrganizer = ref(false);
    const chatOpen = ref(false);
    const currentUser = useCurrentUser();

    let shakaPlayer: any = null;
    let syncHandler: ReturnType<typeof createLiveSyncHandler> | null = null;
    let controlsTimeout: ReturnType<typeof setTimeout> | null = null;
    let messageBusHandler: ((data: any) => void) | null = null;

    const eventId = computed(() => Number(route.params.id));
    const isScheduled = computed(() => eventStatus.value === "scheduled");
    const isLive = computed(() => eventStatus.value === "live");
    const isEnded = computed(() => eventStatus.value === "ended" || eventStatus.value === "cancelled");

    const showControls = () => {
      isControlsVisible.value = true;
      if (controlsTimeout) clearTimeout(controlsTimeout);
      controlsTimeout = setTimeout(() => {
        isControlsVisible.value = false;
      }, 3000);
    };

    const initPlayer = async () => {
      if (!videoRef.value || !playerContainerRef.value) return;

      try {
        const shaka = await import("shaka-player");
        shaka.polyfill.installAll();

        if (!shaka.Player.isBrowserSupported()) {
          console.error("[Live] Browser not supported");
          return;
        }

        shakaPlayer = new shaka.Player();
        await shakaPlayer.attach(videoRef.value);

        shakaPlayer.configure({
          abr: { enabled: true },
          streaming: { rebufferingGoal: 2, bufferingGoal: 30 },
        });

        shakaPlayer.addEventListener("buffering", (e: any) => {
          buffering.value = e.buffering;
        });

        shakaPlayer.addEventListener("error", (e: any) => {
          console.error("[Live] Shaka error:", e);
        });

        videoRef.value.addEventListener("ended", () => {
          console.log("[Live] Video ended");
          eventStatus.value = "ended";
        });
      } catch (e) {
        console.error("[Live] Failed to init player:", e);
      }
    };

    const loadContent = async () => {
      try {
        const res = await fetch(`/community/events/${eventId.value}.json`);
        const event = await res.json();
        contentTitle.value = event.content?.title || "";
        eventStatus.value = event.status || "";
        startsAt.value = event.starts_at || "";
        poster.value = event.content?.poster || "";
        isOrganizer.value = !!(event.organizer && currentUser && event.organizer.id === currentUser.id);

        if (event.status === "live" && event.sources && event.sources.length > 0 && shakaPlayer) {
          const source = event.sources[0];
          await shakaPlayer.load(source.url);
          console.log("[Live] Loaded source:", source.url);

          if (event.session_id) {
            const statusRes = await fetch(`/watch_party/sessions/${event.session_id}/status.json`);
            const status = await statusRes.json();

            syncHandler = createLiveSyncHandler(videoRef.value!);
            syncHandler.applyInitialState({
              current_time: status.current_time || 0,
              is_playing: true,
            });
          }
        }
      } catch (e) {
        console.error("[Live] Failed to load content:", e);
      }

      if (typeof window !== "undefined" && (window as any).MessageBus) {
        if (messageBusHandler) {
          (window as any).MessageBus.unsubscribe(`/live/event/*`, messageBusHandler);
        }
        messageBusHandler = (data: any) => {
          if (data.type === "event_started" && data.event_id === eventId.value) {
            loadContent();
          }
          if (data.type === "playback_sync") {
            syncHandler?.handleSync(data);
          }
          if (data.type === "event_ended" && data.event_id === eventId.value) {
            eventStatus.value = "ended";
          }
        };
        (window as any).MessageBus.subscribe(`/live/event/${eventId.value}`, messageBusHandler);
      }
    };

    onMounted(async () => {
      showControls();
      await initPlayer();
      await loadContent();
    });

    onUnmounted(() => {
      if (controlsTimeout) clearTimeout(controlsTimeout);
      if (messageBusHandler && typeof window !== "undefined" && (window as any).MessageBus) {
        (window as any).MessageBus.unsubscribe(`/live/event/*`, messageBusHandler);
        (window as any).MessageBus.unsubscribe(`/watchparty/*`, messageBusHandler);
      }
      if (shakaPlayer) {
        shakaPlayer.destroy();
      }
    });

    const backToEvent = () => {
      router.push({ name: "live.event", params: { id: eventId.value } });
    };

    const toggleChat = () => {
      chatOpen.value = !chatOpen.value;
    };

    return () => (
      <div class="video-container text-white">
        {isScheduled.value && (
          <div class="absolute inset-0 flex flex-col items-center justify-center bg-[#0a0a0f] z-10">
            {poster.value && (
              <img src={poster.value} alt="" class="w-40 h-60 object-cover rounded-xl mb-6 opacity-50" />
            )}
            <p class="text-white/50 text-sm mb-2">La transmisión aún no comenzó</p>
            <h2 class="text-2xl font-bold mb-4">{contentTitle.value}</h2>
            <CountdownTimer targetDate={startsAt.value} />
            <CButton
              onClick={backToEvent}
              class="mt-8 px-6 py-2 rounded-lg bg-white/10 text-white hover:bg-white/20 transition-colors text-sm"
            >
              Volver
            </CButton>
          </div>
        )}

        {isEnded.value && (
          <div class="absolute inset-0 flex flex-col items-center justify-center bg-[#0a0a0f] z-10">
            <p class="text-white/40 text-lg">Esta transmisión ha finalizado</p>
            <CButton
              onClick={backToEvent}
              class="mt-6 px-6 py-2 rounded-lg bg-white/10 text-white hover:bg-white/20 transition-colors text-sm"
            >
              Volver
            </CButton>
          </div>
        )}

        <div class="flex-1 relative flex flex-col min-w-0">
          <div
            ref={playerContainerRef}
            class={`video-shell w-full h-full min-w-0 min-h-0 relative ${!isLive.value ? "invisible" : ""}`}
            onMousemove={showControls}
          >
            <video
              ref={videoRef}
              class="w-full h-full object-contain bg-black"
              autoplay
              playsinline
            />

            {buffering.value && isLive.value && (
              <div class="pointer-events-none absolute inset-0 z-50 flex items-center justify-center">
                <div class="w-16 h-16 rounded-full bg-black/40 backdrop-blur-sm flex items-center justify-center border border-white/[0.08]">
                  <CSpinner class="w-8 h-8" />
                </div>
              </div>
            )}

            {isLive.value && (
              <div
                class={`absolute inset-0 z-[99] pointer-events-none transition-opacity duration-300 ${
                  isControlsVisible.value ? "opacity-100" : "opacity-0"
                }`}
              >
                <LiveReactions eventId={eventId.value} />
                <div class="absolute top-0 left-0 right-0 flex items-center justify-between px-4 py-3 bg-gradient-to-b from-black/70 to-transparent pointer-events-auto">
                  <CButton
                    onClick={backToEvent}
                    class="flex items-center gap-2 text-sm text-white/80 hover:text-white transition-colors"
                  >
                    <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
                    </svg>
                    <span class="hidden sm:inline">{contentTitle.value}</span>
                  </CButton>
                  <div class="flex items-center gap-3">
                    <CButton
                      onClick={toggleChat}
                      class={`p-2 rounded-lg transition-colors ${chatOpen.value ? "bg-white/20 text-white" : "text-white/60 hover:text-white hover:bg-white/10"}`}
                      title="Chat"
                    >
                      <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                      </svg>
                    </CButton>
                    <LiveIndicator />
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>

        {isLive.value && chatOpen.value && (
          <div class="w-80 flex-shrink-0">
            <LiveChat eventId={eventId.value} isOrganizer={isOrganizer.value} />
          </div>
        )}
      </div>
    );
  },
});
