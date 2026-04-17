import { computed, defineComponent, onBeforeUnmount, onMounted, ref, provide } from 'vue';
import { useSiteSettings } from '@/app/services/site-settings';
import { onBeforeRouteLeave, useRoute, useRouter } from "vue-router";
import { ajax } from "@/lib/Ajax";
import { useHead } from "unhead";
import { toast } from "vue-sonner";
import { getGoogleDriveVideoInfo } from "@/app/utils/GoogleDriveParser";

/* import 'vidstack/player';
import 'vidstack/player/ui';
import { MediaPlayer } from "vidstack"; */
import { defineCustomElement, MediaTitleElement, MediaSpinnerElement, MediaQualityRadioGroupElement } from "vidstack/elements";
import 'vidstack/bundle';


import CSpinner from "@/components/c-spinner";
import CIcon from "@/components/c-icon.vue";
import CButton from "@/components/forms/c-button";
import PlayerGestures from "@/components/videoplayer/PlayerGestures";
import PlayerSlider from "@/components/videoplayer/PlayerSlider";
import PlayerVolumeSlider from "@/components/videoplayer/PlayerVolumeSlider";
import PlayerTopControls from "@/components/videoplayer/PlayerTopControls";
import { useContinueWatching } from "@/composables/useContinueWatching";
import { AxiosError } from "axios";
import PluginOutlet from "@/components/PluginOutlet";

const DEFAULT_STREAM_PING_INTERVAL_MS = 10_000;
const STREAM_LIMIT_ERROR_MESSAGE = 'Has alcanzado el número máximo de transmisiones simultáneas.';

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

function handleFetchError(response: AxiosError['response']['data']) {
    const responseData = response as any;
    console.log({ responseData });
    const errorType =
        responseData?.errors?.[0]?.error_type ||
        responseData?.error_type;
    const errorMsg =
        (Array.isArray(responseData?.errors) && responseData.errors[0]) ||
        responseData?.message ||
        'Error al cargar el video.';

    if (errorType === 'content_not_available') {
        toast.error(errorMsg || 'Contenido no disponible');
    } else if (errorType === 'subscription_required') {
        toast.error(errorMsg || 'Se requiere suscripción activa.');
        return 'redirect';
    } else {
        toast.error(errorMsg);
    }
}

export default defineComponent({
    name: "VideoPlayer",
    setup() {
        defineCustomElement(MediaTitleElement);
        defineCustomElement(MediaSpinnerElement);
        defineCustomElement(MediaQualityRadioGroupElement);

        const { siteSettings } = useSiteSettings();
        const route = useRoute();
        const { replace: replaceRoute } = useRouter();
        const { contentId, episodeId } = route.params as { contentId: string; episodeId?: string };

        // Provide contentId for plugins (like WatchParty)
        provide('playerContentId', contentId);
        provide('playerEpisodeId', episodeId || null);

        const watchData = ref<any>(null);
        const streamLimitError = ref<string | null>(null);
        const streamLimitSessions = ref<any[]>([]);
        const googleCastEnabled = computed(() => siteSettings?.enable_chromecast || false);
        const isShow = computed(() => watchData.value?.content?.content_type === 'TVSHOW');

        const videoPlayer = ref<MediaPlayer | null>(null);
        const isOnFullscreen = ref(false);
        const sources = ref<{ src: string; type: string }[]>([]);
        const streamPingToken = ref<string | null>(null);
        let pingInterval: ReturnType<typeof setInterval> | null = null;
        const STREAM_PING_INTERVAL_MS = DEFAULT_STREAM_PING_INTERVAL_MS;

        const storageKey = (episodeIdParam?: string) => `cinelar_stream_session:${contentId}:${episodeIdParam || episodeId || 'movie'}`;

        const getStoredSessionToken = (): string | null => {
            if (typeof window === 'undefined') return null;
            const token = window.sessionStorage.getItem(storageKey());
            if (token) return token;

            if (!episodeId) {
                const prefix = `cinelar_stream_session:${contentId}:`;
                for (let i = 0; i < window.sessionStorage.length; i++) {
                    const key = window.sessionStorage.key(i);
                    if (key?.startsWith(prefix)) {
                        const stored = window.sessionStorage.getItem(key);
                        if (stored) return stored;
                    }
                }
            }

            return null;
        };

        const saveSessionToken = (token: string, episodeIdParam?: string) => {
            if (typeof window === 'undefined' || !token) return;
            window.sessionStorage.setItem(storageKey(episodeIdParam), token);
            streamPingToken.value = token;
        };

        const saveSessionTokenForRedirect = (token: string, targetEpisodeId?: string) => {
            saveSessionToken(token);
            if (!episodeId && targetEpisodeId) {
                saveSessionToken(token, targetEpisodeId);
            }
        };

        const clearSessionToken = () => {
            if (typeof window === 'undefined') return;
            window.sessionStorage.removeItem(storageKey());
            streamPingToken.value = null;
        };

        const watchUrl = () => {
            const base = episodeId ? `/watch/${contentId}/${episodeId}.json` : `/watch/${contentId}.json`;
            const token = getStoredSessionToken();
            return token ? `${base}?deviceSessionToken=${encodeURIComponent(token)}` : base;
        };

        const stopStreamPing = () => {
            if (pingInterval) {
                clearInterval(pingInterval);
                pingInterval = null;
            }
        };

        const pingStreamSession = async (sessionId: string) => {
            try {
                await ajax.post('/stream/ping', { session_id: sessionId });
            } catch (error) {
                console.warn('[StreamSession] ping failed', error);
            }
        };

        const startStreamPing = (sessionId: string) => {
            if (!sessionId) return;
            stopStreamPing();
            pingInterval = setInterval(() => pingStreamSession(sessionId), STREAM_PING_INTERVAL_MS);
            streamPingToken.value = sessionId;
        };

        const { updateProgress } = useContinueWatching({ contentId, episodeId });

        async function fetchData() {
            stopStreamPing();
            try {
                const url = watchUrl();
                const { data } = await ajax.get(url);
                const contentData = data.data;
                watchData.value = contentData;
                streamLimitError.value = null;
                streamLimitSessions.value = [];

                if (contentData.deviceSessionToken) {
                    const redirectEpisodeId = !episodeId
                        ? contentData.episode?.id || contentData.season?.episodes?.[0]?.id
                        : undefined;

                    saveSessionTokenForRedirect(contentData.deviceSessionToken, redirectEpisodeId);
                    startStreamPing(contentData.deviceSessionToken);
                } else {
                    clearSessionToken();
                }

                if (shouldRedirect(contentData, isShow.value, episodeId, contentId, replaceRoute)) return;

                if (contentData.sources?.length) {
                    sources.value = processVideoSources(contentData.sources, siteSettings?.enable_google_drive_parser);
                }

                useHead({ title: contentData.content?.title });
            } catch (error) {
                const responseData = error?.response?.data || error;

                if (responseData?.error === 'STREAM_LIMIT_REACHED') {
                    streamLimitError.value = STREAM_LIMIT_ERROR_MESSAGE;
                    streamLimitSessions.value = responseData.sessions || [];
                    clearSessionToken();
                    return;
                }

                const action = handleFetchError(responseData);
                if (action === 'redirect') {
                    backToContent();
                }
            }
        }

        /* 
            Mientras esté en este componente
            El body debe tener la clase video-player
            para aplicar estilos específicos
        */



        onMounted(async () => {
            document.body.classList.add('video-player');

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



        });

        onBeforeUnmount(() => {
            document.body.classList.remove('video-player');
            stopStreamPing();
        });


        const backToContent = () => {
            if (!contentId) return;
            if (isOnFullscreen.value) document.exitFullscreen();
            replaceRoute({ name: "content.show", params: { id: contentId } });
        };

        // ---------- Render ----------
        return () => {
            if (streamLimitError.value) {
                return (
                    <div class="video-container">
                        <div class="stream-limit-overlay" role="alert" aria-live="assertive">
                            <div class="stream-limit-copy">
                                <div class="stream-limit-title">Límite de transmisiones alcanzado</div>
                                <div class="stream-limit-message">{streamLimitError.value}</div>
                            </div>

                            {streamLimitSessions.value.length > 0 && (
                                <div class="stream-limit-list">
                                    <div class="stream-limit-list__title">Sesiones activas</div>
                                    <ul class="stream-limit-list__items">
                                        {streamLimitSessions.value.map((session) => (
                                            <li key={session.session_id} class="stream-limit-list__item">
                                                <div class="stream-limit-item__heading">
                                                    <CIcon icon="tv" size={16} class="stream-limit-item__icon" />
                                                    <span class="stream-limit-item__name">{session.device_name || 'Dispositivo desconocido'}</span>
                                                </div>
                                                <div class="stream-limit-item__meta">{session.device_type || 'desconocido'} · TTL: {session.ttl}s</div>
                                            </li>
                                        ))}
                                    </ul>
                                </div>
                            )}

                            <div class="stream-limit-actions">
                                <CButton onClick={backToContent}>
                                    Volver al contenido
                                </CButton>
                            </div>
                        </div>
                    </div>
                );
            }

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
                        class="video-shell w-full h-full min-w-0 min-h-0"
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
                                            <media-time class="time tabular-nums" type="current"></media-time>
                                            <div class="mx-1 text-white/50">/</div>
                                            <media-time class="time tabular-nums text-white/50" type="duration"></media-time>
                                        </div>
                                        <PlayerVolumeSlider playerElement={videoPlayer.value as MediaPlayer} />
                                    </div>
                                </div>
                            </media-controls-group>
                        </media-controls>
                    </media-player>
                    <PluginOutlet name="player:after-media-player" />
                </div>
            );
        };
    }
});
