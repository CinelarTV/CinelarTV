import { defineComponent, ref, onMounted, onBeforeUnmount } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { ajax } from '@/lib/Ajax';
import { useHead } from 'unhead';
import { toast } from 'vue-sonner';
import { useSiteSettings } from '@/app/services/site-settings';

import 'vidstack/player/styles/base.css';
import 'vidstack/player';
import 'vidstack/player/ui';
import { defineCustomElement, MediaTitleElement, MediaSpinnerElement } from 'vidstack/elements';
import { MediaPlayer } from 'vidstack';

import CSpinner from '@/components/c-spinner';
import CIcon from '@/components/c-icon.vue';
import PlayerGestures from '@/components/videoplayer/PlayerGestures';
import PlayerVolumeSlider from '@/components/videoplayer/PlayerVolumeSlider';
import PlayerTopControls from '@/components/videoplayer/PlayerTopControls';

export default defineComponent({
    name: 'LiveTvPlayer',
    setup() {
        defineCustomElement(MediaTitleElement);
        defineCustomElement(MediaSpinnerElement);

        const { siteSettings } = useSiteSettings();
        const route = useRoute();
        const router = useRouter();
        const channelId = route.params.id as string;

        const channelData = ref<any>(null);
        const currentProgram = ref<any>(null);
        const epgOpen = ref(false);
        const epgLoading = ref(false);
        const epgPrograms = ref<any[]>([]);
        const videoPlayer = ref<MediaPlayer | null>(null);
        const isOnFullscreen = ref(false);
        const isLoading = ref(true);

        useHead({ title: 'Live TV' });

        async function fetchData() {
            try {
                isLoading.value = true;
                const { data } = await ajax.get(`/live/${channelId}.json`);
                channelData.value = data.live_tv_channel;
                currentProgram.value = data.live_tv_channel.current_program;

                if (channelData.value) {
                    useHead({ title: `${channelData.value.name}` });
                }
            } catch (error: any) {
                const errorMsg = error?.response?.data?.error || 'Error al cargar el canal en vivo.';
                toast.error(errorMsg);
                router.replace('/');
            } finally {
                isLoading.value = false;
            }
        }

        onMounted(async () => {
            document.body.classList.add('video-player');
            await fetchData();

            const player = videoPlayer.value;
            if (!player) return;

            player.addEventListener('fullscreenchange', () => {
                isOnFullscreen.value = !!document.fullscreenElement;
            });
        });

        onBeforeUnmount(() => {
            document.body.classList.remove('video-player');
        });

        const backToLiveTv = () => {
            if (isOnFullscreen.value) document.exitFullscreen();
            router.replace({ name: 'live_tv.index' });
        };

        const backToContent = backToLiveTv;
        const loadGuide = async () => {
            try {
                epgLoading.value = true;
                const nowIso = new Date().toISOString();
                const { data } = await ajax.get(`/live_tv/${channelId}/guide.json?start_time=${encodeURIComponent(nowIso)}`);
                epgPrograms.value = data.programs || [];
            } catch (_error: any) {
                epgPrograms.value = [];
                toast.error('No se pudo cargar la guia EPG.');
            } finally {
                epgLoading.value = false;
            }
        };

        const toggleEpgPanel = async () => {
            epgOpen.value = !epgOpen.value;
            if (epgOpen.value && epgPrograms.value.length === 0) {
                await loadGuide();
            }
        };

        const formatProgramTime = (value: string) => {
            const date = new Date(value);
            if (Number.isNaN(
                date.getTime())) return '--:--';

            return date.toLocaleTimeString('es-ES', {
                hour: '2-digit',
                minute: '2-digit'
            });
        };

        const isProgramLive = (program: any) => {
            const now = new Date().getTime();
            const start = new Date(program.start_time).getTime();
            const end = new Date(program.end_time).getTime();
            return !Number.isNaN(start) && !Number.isNaN(end) && start <= now && end >= now;
        };

        return () => {
            if (isLoading.value || !channelData.value) {
                return (
                    <div class="video-container">
                        <CSpinner class="w-full h-full" />
                    </div>
                );
            }

            const streamUrl = channelData.value.stream_url;
            let streamType = 'application/x-mpegurl'; // Default to HLS

            if (channelData.value.stream_format === 'dash') {
                streamType = 'application/dash+xml';
            }

            const displayPrograms = epgPrograms.value
                .filter((program) => {
                    const endTime = new Date(program.end_time).getTime();
                    return !Number.isNaN(endTime) && endTime >= Date.now();
                })
                .sort((a, b) => new Date(a.start_time).getTime() - new Date(b.start_time).getTime())
                .slice(0, 20);

            return (
                <div class="video-container">
                    <media-player
                        ref={videoPlayer}
                        class="video-shell w-full h-full min-w-0 min-h-0"
                        autoplay
                        title={`${channelData.value.name}`}
                        live
                        streamType="live"
                    >
                        <media-provider>
                            <media-poster
                                class="absolute inset-0 block h-full w-full rounded-md bg-black opacity-0 transition-opacity data-[visible]:opacity-100 [&>img]:h-full [&>img]:w-full [&>img]:object-cover"
                                src={channelData.value.logo_url || ''}
                                alt={channelData.value.name}
                            />
                            <source src={streamUrl} type={streamType} />
                        </media-provider>

                        <PlayerGestures />
                        <div class="pointer-events-none absolute inset-0 z-50 flex h-full w-full items-center justify-center">
                            <media-spinner
                                class="text-white opacity-0 transition-opacity duration-200 ease-linear media-buffering:animate-spin media-buffering:opacity-100 [&>[data-part='track']]:opacity-25"
                                size="96"
                                track-width="8"
                            >
                                Cargando
                            </media-spinner>
                            <div class="absolute inset-0 flex items-center justify-center opacity-0 media-buffering:opacity-100">
                                <CSpinner class="w-16 h-16 text-white" />
                            </div>
                        </div>

                        {epgOpen.value && (
                            <aside class="pointer-events-auto absolute bottom-28 left-2 right-2 z-[120] w-auto overflow-hidden rounded-xl border border-white/15 bg-black/85 shadow-2xl backdrop-blur sm:bottom-auto sm:left-auto sm:right-4 sm:top-16 sm:w-[min(92vw,380px)]">
                                <div class="flex items-center justify-between border-b border-white/10 px-4 py-3">
                                    <div>
                                        <p class="text-[11px] uppercase tracking-wide text-white/60">Programacion</p>
                                        <h3 class="text-sm font-semibold text-white">EPG {channelData.value.name}</h3>
                                    </div>
                                    <button
                                        type="button"
                                        class="rounded-md border border-white/15 px-2.5 py-1 text-xs font-semibold text-white/80 transition hover:bg-white/10"
                                        onClick={toggleEpgPanel}
                                    >
                                        Cerrar
                                    </button>
                                </div>

                                <div class="max-h-[58vh] overflow-y-auto p-3">
                                    {epgLoading.value ? (
                                        <div class="flex items-center justify-center py-8">
                                            <CSpinner class="h-8 w-8 text-white" />
                                        </div>
                                    ) : displayPrograms.length === 0 ? (
                                        <p class="text-sm text-white/70">Sin programa actual o proximo disponible.</p>
                                    ) : (
                                        <div class="space-y-2">
                                            {displayPrograms.map((program) => (
                                                <div
                                                    key={`${program.id}-${program.start_time}`}
                                                    class={`rounded-lg border px-3 py-2 ${isProgramLive(program)
                                                            ? 'border-red-400/60 bg-red-500/15'
                                                            : 'border-white/10 bg-white/5'
                                                        }`}
                                                >
                                                    <div class="mb-1 flex items-center justify-between">
                                                        <span class="text-xs text-white/70">
                                                            {formatProgramTime(program.start_time)} - {formatProgramTime(program.end_time)}
                                                        </span>
                                                        {isProgramLive(program) && (
                                                            <span class="rounded bg-red-600 px-1.5 py-0.5 text-[10px] font-bold uppercase text-white">En emision</span>
                                                        )}
                                                    </div>
                                                    <p class="text-sm font-semibold text-white">{program.title}</p>
                                                </div>
                                            ))}
                                        </div>
                                    )}
                                </div>
                            </aside>
                        )}

                        <media-controls class="pointer-events-none absolute inset-0 z-99 flex h-full w-full flex-col opacity-0 transition-opacity data-[visible]:opacity-100 media-buffering:opacity-100 in-media-buffering:opacity-100">
                            <PlayerTopControls
                                googleCastEnabled={siteSettings?.enable_chromecast || false}
                                backToContent={backToContent}
                                content={{
                                    content: {
                                        title: channelData.value.name,
                                        banner: channelData.value.logo_url,
                                    },
                                }}
                            />

                            {/* Live badge overlay */}
                            <div class="absolute top-16 left-4 z-10 flex items-center gap-2">
                                <div class="flex items-center gap-1.5 rounded bg-red-600 px-2.5 py-1 text-xs font-bold uppercase text-white">
                                    <div class="h-2 w-2 animate-pulse rounded-full bg-white"></div>
                                    Live
                                </div>
                                {currentProgram.value && (
                                    <div class="rounded bg-black/70 px-3 py-1 text-sm text-white">
                                        <span class="font-semibold">{currentProgram.value.title}</span>
                                    </div>
                                )}
                            </div>

                            <div class="flex-1"></div>
                            <media-controls-group class="pointer-events-auto flex w-full justify-center items-center px-2">
                                <media-play-button class="group relative inline-flex size-24 cursor-pointer items-center justify-center rounded-md outline-none ring-inset ring-sky-400 hover:bg-white/20 data-[focus]:ring-4">
                                    <CIcon icon="play" size={40} class="hidden group-data-[paused]:block" />
                                    <CIcon icon="pause" size={40} class="group-data-[paused]:hidden" />
                                </media-play-button>
                            </media-controls-group>
                            <div class="flex-1"></div>

                            {/* Live TV controls - no time slider, just volume */}
                            <media-controls-group class="pointer-events-auto bg-gradient-to-t from-black h-24 to-transparent px-4">
                                <div class="max-w-7xl mx-auto w-full flex-col flex">
                                    {/* Live indicator with current program info */}
                                    {currentProgram.value && (
                                        <div class="mb-2 flex items-center justify-between text-sm text-white/80">
                                            <div class="flex items-center gap-2">
                                                <CIcon icon="broadcast" size={16} class="text-red-500" />
                                                <span class="font-medium">{currentProgram.value.title}</span>
                                            </div>
                                            {currentProgram.value.description && (
                                                <span class="text-white/60 truncate max-w-md">
                                                    {currentProgram.value.description}
                                                </span>
                                            )}
                                        </div>
                                    )}
                                    <div class="flex flex-wrap items-center gap-2 text-sm font-medium sm:gap-x-4">
                                        <div class="flex items-center text-red-500 font-bold shrink-0">
                                            <span class="uppercase">EN VIVO</span>
                                        </div>
                                        <PlayerVolumeSlider playerElement={videoPlayer.value as MediaPlayer} />
                                        <button
                                            type="button"
                                            class={`inline-flex h-9 shrink-0 items-center justify-center gap-2 rounded-md border px-3 text-xs font-semibold text-white transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-white/60 ${epgOpen.value
                                                ? 'border-white/40 bg-white/20'
                                                : 'border-white/20 bg-black/40 hover:bg-black/60'
                                                }`}
                                            onClick={toggleEpgPanel}
                                            aria-label="Mostrar EPG"
                                        >
                                            <CIcon icon="calendar" size={14} />
                                            <span class="hidden sm:inline">EPG</span>
                                        </button>
                                    </div>
                                </div>
                            </media-controls-group>
                        </media-controls>
                    </media-player>
                </div>
            );
        };
    }
});
