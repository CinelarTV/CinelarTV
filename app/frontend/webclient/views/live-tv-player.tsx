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

            return (
                <div class="video-container">
                    <media-player
                        ref={videoPlayer}
                        class="w-full h-full grow min-w-0"
                        autoplay
                        title={`${channelData.value.name}`}
                        live
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
                                    <div class="flex items-center text-sm font-medium gap-x-4">
                                        <div class="flex items-center text-red-500 font-bold">
                                            <span class="uppercase">EN VIVO</span>
                                        </div>
                                        <PlayerVolumeSlider playerElement={videoPlayer.value as MediaPlayer} />
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
