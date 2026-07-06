import { computed, defineComponent, onBeforeUnmount, onMounted, ref, provide, watch, nextTick } from 'vue';

import { useSiteSettings } from '@/app/services/site-settings';
import { useCurrentUser } from '@/app/services/current-user';

import { onBeforeRouteLeave, useRoute, useRouter } from "vue-router";

import { ajax } from "@/lib/Ajax";

import { useHead } from "unhead";

import { toast } from "vue-sonner";

import { getGoogleDriveVideoInfo } from "@/app/utils/GoogleDriveParser";

import shaka from 'shaka-player';

import CSpinner from "@/components/c-spinner";
import CIcon from "@/components/c-icon.vue";
import CButton from "@/components/forms/c-button";
import PlayerGestures from "@/components/videoplayer/PlayerGestures";
import PlayerSlider from "@/components/videoplayer/PlayerSlider";
import PlayerVolumeSlider from "@/components/videoplayer/PlayerVolumeSlider";
import PlayerTopControls from "@/components/videoplayer/PlayerTopControls";
import { useContinueWatching } from "@/composables/useContinueWatching";
import { useMediaPlayerState } from "@/composables/useMediaPlayerState";
import { useChromecast } from "@/composables/useChromecast";
import { AxiosError } from "axios";
import PluginOutlet from "@/components/PluginOutlet";
import pluginEvents from "@/lib/plugin-events";
import PlayerSkipButton from "@/components/videoplayer/PlayerSkipButton";
import PlayerNextEpisode from "@/components/videoplayer/PlayerNextEpisode";
import PlayerSegmentAdmin from "@/components/videoplayer/PlayerSegmentAdmin";

const DEFAULT_STREAM_PING_INTERVAL_MS = 10_000;
const STREAM_LIMIT_ERROR_MESSAGE = 'Has alcanzado el número máximo de transmisiones simultáneas.';

// ---------- Pure functions ----------
function shouldRedirect(data, isShow, episodeId, contentId, replaceRoute) {
    if (isShow && !episodeId && !data.episode?.id) {
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

function getMimeType(src, format) {
    if (format === 'm3u8') return 'application/x-mpegurl';
    if (src?.match(/\.m3u8/i)) return 'application/x-mpegurl';
    if (src?.match(/\.webm/i)) return 'video/webm';
    return 'video/mp4';
}

function processVideoSources(sources, enableGoogleDriveParser) {
    if (!Array.isArray(sources)) return [];

    let processedSources = sources.map(src => ({
        src: src.url,
        type: getMimeType(src.url, src.format)
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

    return processedSources;
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
        return 'redirect';
    } else if (errorType === 'subscription_required') {
        toast.error(errorMsg || 'Se requiere suscripción activa.');
        return 'redirect';
    } else {
        toast.error(errorMsg);
    }
}

function formatTime(seconds: number): string {
    if (!isFinite(seconds)) return '0:00';
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = Math.floor(seconds % 60);
    if (h > 0) return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
    return `${m}:${s.toString().padStart(2, '0')}`;
}

export default defineComponent({
    name: "VideoPlayer",
    setup() {
        const { siteSettings } = useSiteSettings();
        const { currentUser } = useCurrentUser();
        const route = useRoute();
        const { replace: replaceRoute } = useRouter();
        const contentId = computed(() => route.params.contentId as string);
        const episodeId = computed(() => route.params.episodeId as string | undefined);

        provide('playerContentId', contentId);
        provide('playerEpisodeId', episodeId);

        const watchData = ref<any>(null);
        const streamLimitError = ref<string | null>(null);
        const streamLimitSessions = ref<any[]>([]);
        const googleCastEnabled = computed(() => siteSettings?.enable_chromecast || false);
        const isShow = computed(() => watchData.value?.content?.content_type === 'TVSHOW');

        const videoRef = ref<HTMLVideoElement | null>(null);
        const playerContainerRef = ref<HTMLDivElement | null>(null);
        const isOnFullscreen = ref(false);
        const sources = ref<{ src: string; type: string }[]>([]);
        const streamPingToken = ref<string | null>(null);
        let pingInterval: ReturnType<typeof setInterval> | null = null;

        const segments = computed(() =>
            watchData.value?.episode?.segments || watchData.value?.content?.segments || []
        );

        const nextEpisode = computed(() => {
            if (!isShow.value || !watchData.value?.seasons) return null;
            const currentEpisodeId = watchData.value?.episode?.id;
            const seasons = watchData.value.seasons;
            for (let seasonIndex = 0; seasonIndex < seasons.length; seasonIndex++) {
                const season = seasons[seasonIndex];
                const episodes = season.episodes || [];
                const currentIndex = episodes.findIndex(ep => ep.id === currentEpisodeId);
                if (currentIndex !== -1) {
                    if (currentIndex < episodes.length - 1) {
                        return episodes[currentIndex + 1];
                    }
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

        // Shaka Player instance (NOT reactive — Vue Proxy breaks it)
        let shakaPlayer: shaka.Player | null = null;
        let eventManager: any = null;
        const playerReady = ref(false);

        const mediaState = useMediaPlayerState();
        const chromecast = useChromecast();

        const handleSkipSegment = (endTime: number) => {
            mediaState.seek(endTime);
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

        // ---------- useContinueWatching ----------
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

        // ---------- Playback state sync ----------
        let lastSeekTime = 0;
        let lastPaused = true;

        function syncPlaybackState() {
            const video = videoRef.value;
            if (!video) return;

            const currentPaused = video.paused;
            if (lastPaused !== currentPaused) {
                lastPaused = currentPaused;
                if (currentPaused) forceSaveProgress?.();
                pluginEvents.emit(currentPaused ? 'playback:pause' : 'playback:play', {
                    contentId: contentId.value,
                    episodeId: episodeId.value,
                    currentTime: video.currentTime,
                });
            }

            if (!currentPaused) {
                updateProgress?.(video.currentTime, video.duration || 0);
            }
        }

        const isControlsVisible = ref(true);
        let controlsTimeout: ReturnType<typeof setTimeout> | null = null;

        function showControls() {
            isControlsVisible.value = true;
            if (controlsTimeout) clearTimeout(controlsTimeout);
            controlsTimeout = setTimeout(() => {
                if (!mediaState.paused.value) {
                    isControlsVisible.value = false;
                }
            }, 3000);
        }

        // ---------- Shaka initialization ----------
        async function initShakaPlayer() {
            const video = videoRef.value;
            if (!video) {
                console.warn('[Shaka] No video element found');
                return;
            }
            console.log('[Shaka] Initializing...');

            if (shakaPlayer) {
                eventManager?.removeAll();
                await shakaPlayer.destroy();
                shakaPlayer = null;
                eventManager = null;
                playerReady.value = false;
            }

            shaka.polyfill.installAll();

            if (!shaka.Player.isBrowserSupported()) {
                console.error('Shaka Player: browser not supported');
                return;
            }

            shakaPlayer = new shaka.Player();
            await shakaPlayer.attach(video);

            // Emit before-init hook — plugins can modify config
            const pendingConfigs: Record<string, any>[] = [];
            pluginEvents.emit('player:before-init', {
                video,
                configure: (cfg: Record<string, any>) => pendingConfigs.push(cfg),
            });

            // Aggressive ABR configuration — ramp up faster
            shakaPlayer.configure({
                abr: {
                    enabled: true,
                    defaultBandwidthEstimate: 3_000_000,
                    bandwidthUpgradeTarget: 0.85,
                    bandwidthDowngradeTarget: 0.95,
                },
                streaming: {
                    rebufferingGoal: 2,
                    bufferingGoal: 30,
                },
            });

            // Apply plugin configs (after defaults, so plugins can override)
            for (const cfg of pendingConfigs) {
                shakaPlayer.configure(cfg);
            }

            eventManager = new shaka.util.EventManager();

            mediaState.attach(shakaPlayer, video, eventManager);

            // Emit after-init hook — plugins can access networking engine, etc.
            pluginEvents.emit('player:after-init', {
                player: shakaPlayer,
                video,
                netEngine: shakaPlayer.getNetworkingEngine(),
            });

            eventManager.listen(shakaPlayer, 'error', (event: any) => {
                const error = event.detail;
                console.error('Shaka error:', error.code, error);
                toast.error('Error al reproducir el video.');
            });

            eventManager.listen(video, 'timeupdate', syncPlaybackState);
            eventManager.listen(video, 'seeking', () => { lastSeekTime = Date.now(); });
            eventManager.listen(video, 'seeked', () => {
                if (lastSeekTime > 0 && Date.now() - lastSeekTime > 100) {
                    lastSeekTime = 0;
                    forceSaveProgress?.();
                }
            });

            eventManager.listen(document, 'fullscreenchange', () => {
                isOnFullscreen.value = !!document.fullscreenElement;
            });

            if (googleCastEnabled.value) {
                chromecast.init(shakaPlayer, video);
            }

            playerReady.value = true;
            console.log('[Shaka] Player ready, sources:', sources.value);

            if (sources.value.length > 0) {
                await loadSource(sources.value[0]);
            }
        }

        // ---------- Load + seek helper ----------
        let loadingSource = false;
        async function loadSource(source: { src: string; type: string }) {
            if (!shakaPlayer || loadingSource) return;
            loadingSource = true;
            const video = videoRef.value;
            try {
                pluginEvents.emit('player:before-load', { player: shakaPlayer, src: source.src });
                console.log('[Shaka] Loading:', source.src);
                await shakaPlayer.load(source.src);
                console.log('[Shaka] Load complete');

                if (video && video.readyState < 1) {
                    await new Promise<void>((resolve) => {
                        const onReady = () => { video.removeEventListener('loadedmetadata', onReady); resolve(); };
                        video.addEventListener('loadedmetadata', onReady);
                        setTimeout(resolve, 2000);
                    });
                }

                const progress = watchData.value?.continue_watching?.progress;
                if (progress > 0 && video) {
                    console.log('[Shaka] Seeking to progress:', progress);
                    video.currentTime = progress;
                }

                pluginEvents.emit('player:after-load', { player: shakaPlayer, video, duration: video?.duration || 0 });

                if (video) {
                    video.play().catch(() => {});
                }
            } catch (error) {
                console.error('[Shaka] Failed to load:', error);
            } finally {
                loadingSource = false;
            }
        }

        watch(playerContainerRef, async (container) => {
            if (!container) return;
            await initShakaPlayer();
        });

        watch(sources, async (newSources) => {
            if (!shakaPlayer || !newSources.length) return;
            await loadSource(newSources[0]);
        }, { deep: true });

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

        watch([() => route.params.contentId, () => route.params.episodeId], () => {
            audioDefaultApplied = false;
            fetchData();
        });

        // Auto-select audio track matching the site's default locale
        let audioDefaultApplied = false;
        watch(() => mediaState.audioTracks.value, (tracks) => {
            if (audioDefaultApplied || tracks.length <= 1) return;
            const defaultLocale = siteSettings?.default_locale;
            if (!defaultLocale) return;
            audioDefaultApplied = true;
            const lang = defaultLocale.split('-')[0].toLowerCase();
            const match = tracks.find(t => t.language.toLowerCase().startsWith(lang));
            if (match && !match.active) {
                mediaState.selectAudioTrack(match.language, match.roles[0]);
            }
        });

        onMounted(async () => {
            document.body.classList.add('video-player');
            await fetchData();
        });

        // Keyboard shortcuts
        function handleKeydown(e: KeyboardEvent) {
            const tag = (e.target as HTMLElement)?.tagName;
            if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return;

            switch (e.key) {
                case ' ':
                case 'k':
                    e.preventDefault();
                    togglePlay();
                    showControls();
                    break;
                case 'ArrowLeft':
                    e.preventDefault();
                    mediaState.seek(Math.max(0, mediaState.currentTime.value - 10));
                    showControls();
                    break;
                case 'ArrowRight':
                    e.preventDefault();
                    mediaState.seek(mediaState.currentTime.value + 10);
                    showControls();
                    break;
                case 'ArrowUp':
                    e.preventDefault();
                    mediaState.setVolume(Math.min(1, mediaState.volume.value + 0.1));
                    showControls();
                    break;
                case 'ArrowDown':
                    e.preventDefault();
                    mediaState.setVolume(Math.max(0, mediaState.volume.value - 0.1));
                    showControls();
                    break;
                case 'f':
                    e.preventDefault();
                    mediaState.toggleFullscreen(playerContainerRef.value || undefined);
                    break;
                case 'm':
                    e.preventDefault();
                    mediaState.toggleMute();
                    showControls();
                    break;
            }
        }

        onMounted(() => {
            document.addEventListener('keydown', handleKeydown);
        });

        onBeforeUnmount(() => {
            pluginEvents.emit('player:destroy', { player: shakaPlayer });
            document.removeEventListener('keydown', handleKeydown);
            document.body.classList.remove('video-player');
            stopStreamPing();
            eventManager?.removeAll();
            shakaPlayer?.destroy();
            shakaPlayer = null;
        });

        const backToContent = () => {
            if (!contentId.value) return;
            if (isOnFullscreen.value) document.exitFullscreen();
            replaceRoute({ name: "content.show", params: { id: contentId.value } });
        };

        const togglePlay = () => {
            if (mediaState.paused.value) {
                mediaState.play();
                showControls();
                pluginEvents.emit('player:playback-start', {
                    player: shakaPlayer,
                    contentId: contentId.value,
                    episodeId: episodeId.value,
                });
            } else {
                mediaState.pause();
                isControlsVisible.value = true;
                pluginEvents.emit('player:playback-pause', {
                    player: shakaPlayer,
                    contentId: contentId.value,
                    episodeId: episodeId.value,
                    currentTime: mediaState.currentTime.value,
                });
            }
        };

        function handleContainerMouseMove() {
            showControls();
        }

        // ---------- Render ----------
        return () => {
            // ── Stream limit error state ──
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

            // ── Loading state ──
            if (!watchData.value) {
                return (
                    <div class="video-container">
                        <div class="flex items-center justify-center w-full h-full">
                            <CSpinner class="w-12 h-12" />
                        </div>
                    </div>
                );
            }

            // ── Player ──
            const controlsVisible = isControlsVisible.value || mediaState.paused.value;

            return (
                <div class="video-container">
                    <div
                        ref={playerContainerRef}
                        class="video-shell w-full h-full min-w-0 min-h-0 relative"
                        onMousemove={handleContainerMouseMove}
                    >
                        {/* Video element */}
                        <video
                            ref={videoRef}
                            class="w-full h-full object-contain bg-black"
                            autoplay
                            title={watchData.value.content?.title || "Video"}
                            playsinline
                        />

                        {/* Gesture layer */}
                        <PlayerGestures
                            videoRef={() => videoRef.value}
                            onTogglePlay={togglePlay}
                            onSeek={(delta) => mediaState.seek(mediaState.currentTime.value + delta)}
                            onToggleFullscreen={() => mediaState.toggleFullscreen(playerContainerRef.value || undefined)}
                            onToggleControls={showControls}
                        />

                        {/* Buffering spinner */}
                        <div class="pointer-events-none absolute inset-0 z-50 flex items-center justify-center">
                            <div
                                class={`transition-all duration-300 ease-out ${mediaState.buffering.value
                                    ? 'opacity-100 scale-100'
                                    : 'opacity-0 scale-90'
                                }`}
                            >
                                <div class="w-16 h-16 rounded-full bg-black/40 backdrop-blur-sm flex items-center justify-center border border-white/[0.08]">
                                    <CSpinner class="w-8 h-8" />
                                </div>
                            </div>
                        </div>

                        {/* Controls overlay */}
                        <div
                            class={`pointer-events-none absolute inset-0 z-[99] flex flex-col transition-opacity duration-300 ease-out ${controlsVisible ? 'opacity-100' : 'opacity-0'}`}
                            onMousemove={handleContainerMouseMove}
                        >
                            {/* ── Top controls ── */}
                            <PlayerTopControls
                                googleCastEnabled={googleCastEnabled.value}
                                backToContent={backToContent}
                                content={watchData.value}
                                onCast={chromecast.toggleCast}
                                isCasting={chromecast.isCasting.value}
                                audioTracks={mediaState.audioTracks.value}
                                onSelectAudioTrack={mediaState.selectAudioTrack}
                                variantTracks={mediaState.variantTracks.value}
                                isAutoQuality={mediaState.isAutoQuality.value}
                                activeQuality={mediaState.activeQuality.value}
                                onSelectQuality={mediaState.selectQualityByBandwidth}
                                onEnableAutoQuality={mediaState.enableAutoQuality}
                                contentId={contentId.value}
                                episodeId={episodeId.value}
                                currentTime={mediaState.currentTime.value}
                                isAdmin={currentUser?.admin}
                            />

                            {/* Spacer */}
                            <div class="flex-1" />

                            {/* ── Center play button ── */}
                            <div class="pointer-events-auto flex w-full justify-center items-center px-4">
                                <button
                                    onClick={togglePlay}
                                    class="group relative inline-flex size-[72px] cursor-pointer items-center justify-center rounded-2xl bg-white/[0.10] backdrop-blur-sm border border-white/[0.08] outline-none transition-all duration-200 ease-out hover:bg-white/[0.18] hover:scale-105 active:scale-95 focus-visible:ring-2 focus-visible:ring-[var(--c-player-accent-color,#38bdf8)]"
                                >
                                    <CIcon
                                        icon="play"
                                        size={32}
                                        class={`transition-all duration-200 ease-out ${!mediaState.paused.value ? 'hidden' : 'block'}`}
                                    />
                                    <CIcon
                                        icon="pause"
                                        size={32}
                                        class={`transition-all duration-200 ease-out ${mediaState.paused.value ? 'hidden' : 'block'}`}
                                    />
                                </button>
                            </div>

                            {/* Spacer */}
                            <div class="flex-1" />

                            {/* ── Bottom controls ── */}
                            <div class="pointer-events-auto bg-gradient-to-t from-black/70 via-black/30 to-transparent px-5 pb-4 pt-12">
                                <div class="mx-auto w-full max-w-7xl flex flex-col gap-2.5">
                                    {/* Progress slider */}
                                    <PlayerSlider
                                        currentTime={mediaState.currentTime.value}
                                        duration={mediaState.duration.value}
                                        bufferedEnd={mediaState.bufferedEnd.value}
                                        onSeek={mediaState.seek}
                                    />

                                    {/* Time + Volume row */}
                                    <div class="flex items-center justify-between">
                                        <div class="flex items-center gap-3">
                                            {/* Time display */}
                                            <div class="flex items-center text-sm font-medium tabular-nums">
                                                <span class="text-white/90">{formatTime(mediaState.currentTime.value)}</span>
                                                <span class="mx-1.5 text-white/30">/</span>
                                                <span class="text-white/40">{formatTime(mediaState.duration.value)}</span>
                                            </div>

                                            {/* Volume */}
                                            <PlayerVolumeSlider
                                                volume={mediaState.volume.value}
                                                muted={mediaState.muted.value}
                                                onVolumeChange={mediaState.setVolume}
                                                onToggleMute={mediaState.toggleMute}
                                            />
                                        </div>

                                        {/* Fullscreen */}
                                        <button
                                            onClick={() => {
                                                if (document.fullscreenElement) {
                                                    document.exitFullscreen();
                                                } else {
                                                    document.documentElement.requestFullscreen();
                                                }
                                            }}
                                            class="player-control-btn"
                                            aria-label="Fullscreen"
                                        >
                                            <CIcon icon="maximize" size={18} />
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Skip button overlay */}
                    <PlayerSkipButton
                        segments={segments.value}
                        currentTime={mediaState.currentTime.value}
                        onSkip={handleSkipSegment}
                    />

                    {/* Next episode overlay */}
                    <PlayerNextEpisode
                        key={`next-ep-${episodeId.value || 'movie'}`}
                        segments={segments.value}
                        currentTime={mediaState.currentTime.value}
                        duration={mediaState.duration.value}
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
