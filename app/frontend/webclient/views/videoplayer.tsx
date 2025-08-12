import { computed, defineComponent, onMounted, ref } from 'vue';
import { useSiteSettings } from '@/app/services/site-settings';
import { useRoute, useRouter } from "vue-router";
import { ajax } from "@/lib/Ajax";
import { useHead } from "unhead";
import { toast } from "vue-sonner";
import { getGoogleDriveVideoInfo } from "@/app/utils/GoogleDriveParser";

import 'vidstack/player/styles/base.css';
import 'vidstack/player';
import 'vidstack/player/ui';
import { defineCustomElement, MediaTitleElement, MediaSpinnerElement } from "vidstack/elements";
import { MediaPlayer } from "vidstack";

import CSpinner from "@/components/c-spinner";
import CIcon from "@/components/c-icon.vue";
import PlayerGestures from "@/components/videoplayer/PlayerGestures";
import PlayerSlider from "@/components/videoplayer/PlayerSlider";
import PlayerVolumeSlider from "@/components/videoplayer/PlayerVolumeSlider";
import PlayerTopControls from "@/components/videoplayer/PlayerTopControls";
import { useContinueWatching } from "@/composables/useContinueWatching";

// ---------- Funciones puras ----------
function shouldRedirect(data, isShow, episodeId, contentId, replaceRoute) {
    if (isShow && !episodeId && !data.episode?.id) {
        const firstEpisode = data.season?.episodes?.[0];
        if (firstEpisode) {
            replaceRoute(`/watch/${contentId}/${firstEpisode.id}`);
            return true;
        }
    } else if (!episodeId && data.episode?.id) {
        replaceRoute(`/watch/${contentId}/${data.episode.id}`);
        return true;
    }
    return false;
}

function processVideoSources(sources, enableGoogleDriveParser) {
    if (!Array.isArray(sources)) return [];

    let processedSources = sources.map(src => ({
        src: src.url,
        type: 'video/mp4'
    }));

    if (enableGoogleDriveParser) {
        const driveSources = sources
            .filter(src => src.url?.includes('drive.google.com'))
            .map(src => {
                const info = getGoogleDriveVideoInfo(src.url);
                return info ? { src: info.videourl, type: 'video/mp4' } : null;
            })
            .filter(Boolean);

        processedSources = [
            ...processedSources.filter(src => !src.src?.includes('drive.google.com')),
            ...driveSources
        ];
    }

    const hasYoutube = processedSources.some(src => src.src?.includes('youtube.com'));
    return hasYoutube
        ? processedSources
            .filter(src => src.src?.includes('youtube.com'))
            .map(src => ({ src: src.src, type: "video/youtube" }))
        : processedSources;
}

function handleFetchError(error) {
    if (error.response?.errors?.[0]?.error_type === 'content_not_available') {
        toast.error('Contenido no disponible');
    } else {
        toast.error('Error al cargar el video.');
    }
}

export default defineComponent({
    name: "VideoPlayer",
    setup() {
        defineCustomElement(MediaTitleElement);
        defineCustomElement(MediaSpinnerElement);

        const { siteSettings } = useSiteSettings();
        const route = useRoute();
        const { replace: replaceRoute } = useRouter();
        const { contentId, episodeId } = route.params as { contentId: string; episodeId?: string };

        const watchData = ref<any>(null);
        const googleCastEnabled = computed(() => siteSettings?.enable_chromecast || false);
        const isShow = computed(() => watchData.value?.content?.content_type === 'TVSHOW');

        const videoPlayer = ref<MediaPlayer | null>(null);
        const isOnFullscreen = ref(false);
        const sources = ref<{ src: string; type: string }[]>([]);

        const { updateProgress } = useContinueWatching({ contentId, episodeId });

        async function fetchData() {
            try {
                const url = episodeId ? `/watch/${contentId}/${episodeId}.json` : `/watch/${contentId}.json`;
                const { data } = await ajax.get(url);
                const contentData = data.data;
                watchData.value = contentData;

                if (shouldRedirect(contentData, isShow.value, episodeId, contentId, replaceRoute)) return;

                if (contentData.sources?.length) {
                    sources.value = processVideoSources(contentData.sources, siteSettings?.enable_google_drive_parser);
                }

                useHead({ title: contentData.content?.title });
            } catch (error) {
                handleFetchError(error);
            }
        }

        onMounted(async () => {
            await fetchData();

            const player = videoPlayer.value;
            if (!player) return;

            player.addEventListener('fullscreenchange', () => {
                isOnFullscreen.value = !!document.fullscreenElement;
            });

            if (watchData.value?.continue_watching?.progress) {
                player.currentTime = watchData.value.continue_watching.progress;
            }

            const unsubscribeCurrentTime = player.subscribe(({ paused, playing, currentTime }) => {
                if (paused || !playing) return;
                updateProgress(currentTime, player.duration || 0);
            });

            return () => {
                unsubscribeCurrentTime();
            };



            // Escucha a todos los cambios del elemento <media-player>
            // para depuración, es decir, si cambia un data-*
            const observer = new MutationObserver((mutations) => {
                mutations.forEach((mutation) => {
                    if (mutation.type === 'attributes') {
                        console.log(`[VideoPlayer] Attribute changed: ${mutation.attributeName}`, player.getAttribute(mutation.attributeName!));
                        // Puedes loggear o manejar cambios en atributos/data-*
                        // console.log('Atributo cambiado:', mutation.attributeName, player.getAttribute(mutation.attributeName!));
                    }
                });
            });
            observer.observe(player, {
                attributes: true,
                attributeFilter: undefined, // O especifica ['data-*'] si quieres filtrar
                subtree: false
            });

        });

        const backToContent = () => {
            if (!contentId) return;
            if (isOnFullscreen.value) document.exitFullscreen();
            replaceRoute({ name: "content.show", params: { id: contentId } });
        };

        // ---------- Render ----------
        return () => {
            if (!watchData.value) {
                return (
                    <div class="video-container">
                        <CSpinner class="w-full h-full" />
                    </div>
                );
            }

            const videoSources = sources.value.length
                ? sources.value
                : [{ src: watchData.value.content?.video_url || "", type: "video/mp4" }];

            return (
                <div class="video-container">
                    <media-player
                        ref={videoPlayer}
                        class="w-full h-full"
                        autoplay
                        title={watchData.value.content?.title || "Video"}
                    >
                        <media-provider>
                            <media-poster
                                class="absolute inset-0 block h-full w-full rounded-md bg-black opacity-0 transition-opacity data-[visible]:opacity-100 [&>img]:h-full [&>img]:w-full [&>img]:object-cover"
                                src={watchData.value.content?.banner || ""}
                                alt={watchData.value.content?.title || "Poster"}
                            />
                            {videoSources.map((source, index) => (
                                <source key={`${source.src}-${index}`} src={source.src} type={source.type} />
                            ))}
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
                                googleCastEnabled={googleCastEnabled.value}
                                backToContent={backToContent}
                                content={watchData.value}
                            />
                            <div class="flex-1"></div>
                            <media-controls-group class="pointer-events-auto flex w-full justify-center items-center px-2">
                                <media-play-button class="group relative inline-flex size-24 cursor-pointer items-center justify-center rounded-md outline-none ring-inset ring-sky-400 hover:bg-white/20 data-[focus]:ring-4">
                                    <CIcon icon="play" size={40} class="hidden group-data-[paused]:block" />
                                    <CIcon icon="pause" size={40} class="group-data-[paused]:hidden" />
                                </media-play-button>
                            </media-controls-group>
                            <div class="flex-1"></div>
                            <media-controls-group class="pointer-events-auto bg-gradient-to-t from-black h-32 to-transparent px-4">
                                <div class="max-w-7xl mx-auto w-full flex-col flex">
                                    <PlayerSlider />
                                    <div class="flex items-center text-sm font-medium gap-x-4">
                                        <div class="flex items-center">
                                            <media-time class="time" type="current"></media-time>
                                            <div class="mx-1 text-white/50">/</div>
                                            <media-time class="time text-white/50" type="duration"></media-time>
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
