import { computed, defineComponent, onBeforeUnmount, onMounted, ref, provide, watch, nextTick } from 'vue';

import { useSiteSettings } from '@/app/services/site-settings';

import { onBeforeRouteLeave, useRoute, useRouter } from "vue-router";

import { ajax } from "@/lib/Ajax";

import { useHead } from "unhead";

import { toast } from "vue-sonner";

import { getGoogleDriveVideoInfo } from "@/app/utils/GoogleDriveParser";

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
import pluginEvents from "@/lib/plugin-events";
import { MediaPlayer } from "vidstack";
import PlayerSkipButton from "@/components/videoplayer/PlayerSkipButton";
import PlayerNextEpisode from "@/components/videoplayer/PlayerNextEpisode";

const DEFAULT_STREAM_PING_INTERVAL_MS = 10_000;
const STREAM_LIMIT_ERROR_MESSAGE = 'Has alcanzado el número máximo de transmisiones simultáneas.';

// ---------- Funciones puras ----------
function shouldRedirect(data, isShow, episodeId, contentId, replaceRoute) {
    if (isShow && !episodeId && !data.episode?.id) {
        // Buscar el primer episodio de todas las temporadas
        const firstSeason = data.seasons?.[0];
        const firstEpisode = firstSeason?.episodes?.[0];
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
        const contentId = computed(() => route.params.contentId as string);
        const episodeId = computed(() => route.params.episodeId as string | undefined);

        // Provide reactivo
        provide('playerContentId', contentId);
        provide('playerEpisodeId', episodeId);

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

        const currentTime = ref(0);
        const playerDuration = ref(0);

        const segments = computed(() =>
            watchData.value?.episode?.segments || watchData.value?.content?.segments || []
        );

        const nextEpisode = computed(() => {
            if (!isShow.value || !watchData.value?.seasons) return null;
            const currentEpisodeId = watchData.value?.episode?.id;

            // Buscar en todas las temporadas para encontrar el siguiente episodio
            const seasons = watchData.value.seasons;
            for (let seasonIndex = 0; seasonIndex < seasons.length; seasonIndex++) {
                const season = seasons[seasonIndex];
                const episodes = season.episodes || [];
                const currentIndex = episodes.findIndex(ep => ep.id === currentEpisodeId);

                if (currentIndex !== -1) {
                    // Si hay más episodios en esta temporada
                    if (currentIndex < episodes.length - 1) {
                        return episodes[currentIndex + 1];
                    }
                    // Si es el último episodio de esta temporada, ir al primer episodio de la siguiente
                    if (seasonIndex < seasons.length - 1) {
                        const nextSeason = seasons[seasonIndex + 1];
                        if (nextSeason.episodes?.length > 0) {
                            return nextSeason.episodes[0];
                        }
                    }
                    return null;
                }
            }
            return null;
        });

        const handleSkipSegment = (endTime: number) => {
            if (videoPlayer.value) videoPlayer.value.currentTime = endTime;
        };

        const handleNextEpisode = () => {
            if (nextEpisode.value) {
                stopStreamPing();
                replaceRoute(`/watch/${contentId.value}/${nextEpisode.value.id}`);
            }
        };

        // ---------- Session helpers ----------
        const DEVICE_TOKEN_KEY = 'cinelar_device_session_token';

        const getStoredSessionToken = (): string | null => {
            if (typeof window === 'undefined') return null;
            return window.localStorage.getItem(DEVICE_TOKEN_KEY);
        };

        const saveSessionToken = (token: string) => {
            if (typeof window === 'undefined' || !token) return;
            window.localStorage.setItem(DEVICE_TOKEN_KEY, token);
            streamPingToken.value = token;
        };

        const clearSessionToken = () => {
            if (typeof window === 'undefined') return;
            window.localStorage.removeItem(DEVICE_TOKEN_KEY);
            streamPingToken.value = null;
        };

        const watchUrl = () => {
            const base = episodeId.value
                ? `/watch/${contentId.value}/${episodeId.value}.json`
                : `/watch/${contentId.value}.json`;
            const token = getStoredSessionToken();
            return token ? `${base}?deviceSessionToken=${encodeURIComponent(token)}` : base;
        };

        // ---------- Stream ping ----------
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
            pingInterval = setInterval(() => pingStreamSession(sessionId), DEFAULT_STREAM_PING_INTERVAL_MS);
            streamPingToken.value = sessionId;
        };

        // ---------- useContinueWatching reactivo ----------
        let updateProgress: ReturnType<typeof useContinueWatching>['updateProgress'];
        let forceSaveProgress: ReturnType<typeof useContinueWatching>['forceSave'];

        const initContinueWatching = () => {
            const cw = useContinueWatching({
                contentId: contentId.value,
                episodeId: episodeId.value
            });
            updateProgress = cw.updateProgress;
            forceSaveProgress = cw.forceSave;
        };

        // ---------- Player subscription ----------
        let unsubscribePlayer: (() => void) | null = null;

        let isPaused = true;

        let lastSeekTime = 0;

        const setupPlayerSubscription = (player: MediaPlayer) => {
            unsubscribePlayer?.();
            unsubscribePlayer = player.subscribe(({ paused, playing, currentTime: time, seeking }) => {
                if (isPaused !== paused) {
                    isPaused = paused;
                    if (paused) forceSaveProgress?.();
                    pluginEvents.emit(paused ? 'playback:pause' : 'playback:play', {
                        contentId: contentId.value,
                        episodeId: episodeId.value,
                        currentTime: time,
                    });
                }
                // Guardar después de un seek (cuando seeking pasa de true a false)
                if (seeking) lastSeekTime = Date.now();
                if (!seeking && lastSeekTime > 0 && Date.now() - lastSeekTime > 100) {
                    lastSeekTime = 0;
                    forceSaveProgress?.();
                }
                if (paused || !playing) return;
                updateProgress(time, player.duration || 0);
                currentTime.value = time;
                playerDuration.value = player.duration || 0;
            });

            player.addEventListener('fullscreenchange', () => {
                isOnFullscreen.value = !!document.fullscreenElement;
            });
        };

        // Re-suscribirse cada vez que el player se remonta (key cambia con episodio)
        watch(videoPlayer, (player) => {
            if (!player) return;
            setupPlayerSubscription(player);

            // Restaurar progreso de continue watching tras remonte del player
            const progress = watchData.value?.continue_watching?.progress;
            if (progress) player.currentTime = progress;
        });

        // ---------- fetchData ----------
        async function fetchData() {
            stopStreamPing();
            initContinueWatching();

            try {
                const { data } = await ajax.get(watchUrl());
                const contentData = data.data;
                watchData.value = contentData;
                streamLimitError.value = null;
                streamLimitSessions.value = [];

                if (contentData.deviceSessionToken) {
                    saveSessionToken(contentData.deviceSessionToken);
                    startStreamPing(contentData.deviceSessionToken);
                } else {
                    clearSessionToken();
                }

                if (shouldRedirect(contentData, isShow.value, episodeId.value, contentId.value, replaceRoute)) return;

                if (contentData.sources?.length) {
                    sources.value = processVideoSources(contentData.sources, siteSettings?.enable_google_drive_parser);
                }

                useHead({ title: contentData.content?.title });

                // Restaurar progreso una vez que el player esté disponible
                const progress = contentData.continue_watching?.progress;
                if (progress) {
                    await nextTick();
                    if (videoPlayer.value) videoPlayer.value.currentTime = progress;
                }
            } catch (error) {
                const responseData = error?.response?.data || error;

                if (responseData?.error === 'STREAM_LIMIT_REACHED') {
                    streamLimitError.value = STREAM_LIMIT_ERROR_MESSAGE;
                    streamLimitSessions.value = responseData.sessions || [];
                    clearSessionToken();
                    return;
                }

                const action = handleFetchError(responseData);
                if (action === 'redirect') backToContent();
            }
        }

        watch([() => route.params.contentId, () => route.params.episodeId], fetchData);

        onMounted(async () => {
            document.body.classList.add('video-player');
            await fetchData();
        });

        onBeforeUnmount(() => {
            document.body.classList.remove('video-player');
            stopStreamPing();
            unsubscribePlayer?.();
        });

        const backToContent = () => {
            if (!contentId.value) return;
            if (isOnFullscreen.value) document.exitFullscreen();
            replaceRoute({ name: "content.show", params: { id: contentId.value } });
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
                                                <div class="stream-limit-item__content">
                                                    {session.content_title || 'Contenido desconocido'}
                                                    {session.episode_title && ` · ${session.episode_title}`}
                                                </div>
                                                <div class="stream-limit-item__meta">{session.device_type || 'desconocido'} · TTL: {session.ttl}s</div>
                                            </li>
                                        ))}
                                    </ul>
                                </div>
                            )}

                            <div class="stream-limit-actions">
                                <CButton onClick={backToContent}>Volver al contenido</CButton>
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
                        key={`player-${contentId.value}-${episodeId.value || 'movie'}`}
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
                                currentTime={currentTime.value}
                                isAdmin={true}
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

                    <PlayerSkipButton
                        segments={segments.value}
                        currentTime={currentTime.value}
                        onSkip={handleSkipSegment}
                    />

                    <PlayerNextEpisode
                        key={`next-ep-${episodeId.value || 'movie'}`}
                        segments={segments.value}
                        currentTime={currentTime.value}
                        duration={playerDuration.value}
                        nextEpisode={nextEpisode.value}
                        onNextEpisode={handleNextEpisode}
                        onCancel={() => { }}
                    />

                    <PluginOutlet name="player:after-media-player" />
                </div>
            );
        };
    }
});