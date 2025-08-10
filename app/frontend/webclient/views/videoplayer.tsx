import { defineComponent, ref, onMounted, onBeforeUnmount, inject, watch, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { ajax } from '../lib/Ajax';
import videojs from 'video.js';
import 'video.js/dist/video-js.css';
import { useHead } from 'unhead';
import { toast } from 'vue3-toastify';
import "videojs-youtube/dist/Youtube.min.js";

import CIconButton from '../components/forms/c-icon-button.vue';
import CIcon from "../components/c-icon.vue";
import cButton from "../components/forms/c-button";
import { getGoogleDriveVideoInfo } from "@/app/utils/GoogleDriveParser";
import { useSiteSettings } from "@/app/services/site-settings";

// Constantes
const PROGRESS_UPDATE_INTERVAL = 5000;
const INACTIVITY_TIMEOUT = 3000;

export default defineComponent({
    name: 'PrimeVideoPlayer',
    setup() {
        const { siteSettings } = useSiteSettings();
        const currentUser = inject('currentUser');
        const i18n = inject('I18n');
        const isMobile = inject('isMobile');
        const route = useRoute();
        const router = useRouter();

        // Reactive refs agrupados por funcionalidad
        const playerState = ref({
            data: null,
            loading: true,
            notAvailable: false
        });

        const playbackState = ref({
            isPlaying: false,
            currentTime: 0,
            duration: 0,
            volumeLevel: 1,
            isMuted: false,
            fullscreen: false
        });

        const uiState = ref({
            userActive: true,
            showSkipIntro: false,
            showVolumeSlider: false,
            isDragging: false
        });

        // Refs del DOM
        const videoPlayer = ref(null);
        const videoPlayerRef = ref(null);
        const vplayerOverlay = ref(null);
        const skippersRef = ref(null);

        // Variables de control
        const lastDataSent = ref(0);
        const { id: videoId, episodeId } = route.params;

        // Computed properties
        const progressPercentage = computed(() => {
            if (!playbackState.value.duration) return 0;
            return (playbackState.value.currentTime / playbackState.value.duration) * 100;
        });

        const volumeIcon = computed(() => {
            if (playbackState.value.isMuted) return 'volume-x';
            return playbackState.value.volumeLevel < 0.5 ? 'volume1' : 'volume2';
        });

        const isShow = computed(() => playerState.value.data?.content.content_type === 'TVSHOW');

        // Utility functions
        const formatTime = (seconds) => {
            if (!seconds || isNaN(seconds)) return '0:00';
            const h = Math.floor(seconds / 3600);
            const m = Math.floor((seconds % 3600) / 60);
            const s = Math.floor(seconds % 60);

            if (h > 0) {
                return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
            }
            return `${m}:${s.toString().padStart(2, '0')}`;
        };

        const getVideoType = (url) => {
            const extension = url.split('.').pop();
            const types = {
                mp4: 'video/mp4',
                m3u8: 'application/x-mpegURL'
            };
            return types[extension] || 'video/mp4';
        };

        // Data fetching
        const fetchData = async () => {
            try {
                const url = episodeId ? `/watch/${videoId}/${episodeId}.json` : `/watch/${videoId}.json`;
                const response = await ajax.get(url);
                const data = response.data.data;

                // Validar y redirigir si es necesario
                if (shouldRedirect(data)) return;

                playerState.value.data = data;
                useHead({ title: data.content?.title });

            } catch (error) {
                handleFetchError(error);
            }
        };

        const shouldRedirect = (data) => {
            if (isShow.value && !episodeId && !data.episode?.id) {
                const firstEpisode = data.season?.episodes?.[0];
                if (firstEpisode) {
                    router.replace(`/watch/${videoId}/${firstEpisode.id}`);
                    return true;
                }
            } else if (!episodeId && data.episode?.id) {
                router.replace(`/watch/${videoId}/${data.episode.id}`);
                return true;
            }
            return false;
        };

        const handleFetchError = (error) => {
            if (error.response?.errors?.[0]?.error_type === 'content_not_available') {
                playerState.value.notAvailable = true;
                toast.error('Contenido no disponible');
                return;
            }
            toast.error('Error al cargar el video.');
        };

        // Video source processing
        const processVideoSources = (sources) => {
            if (!Array.isArray(sources)) return [];

            // Procesar fuentes de Google Drive si está habilitado
            if (siteSettings?.enable_google_drive_parser) {
                const driveSources = sources
                    .filter(src => src.url?.includes('drive.google.com'))
                    .map(src => getGoogleDriveVideoInfo(src.url))
                    .filter(Boolean);

                sources = [
                    ...sources.filter(src => !src.url?.includes('drive.google.com')),
                    ...driveSources.map(info => ({ src: info.videourl, type: 'video/mp4' }))
                ];
            }

            // Procesar fuentes de YouTube
            const hasYoutube = sources.some(src => src.url?.includes('youtube.com'));
            if (hasYoutube) {
                return sources.map(src => ({
                    src: src.url,
                    type: "video/youtube"
                }));
            }

            return sources.map(source => ({
                src: source.src || source.url,
                type: getVideoType(source.src || source.url)
            }));
        };

        // Video player setup
        const initializePlayer = () => {
            const sources = processVideoSources(playerState.value.data.sources || []);

            videoPlayer.value = videojs(videoPlayerRef.value, {
                autoplay: true,
                techOrder: ['youtube', 'html5'],
                preload: 'auto',
                responsive: true,
                fill: true,
                inactivityTimeout: route.query.debug ? 0 : INACTIVITY_TIMEOUT,
                poster: playerState.value.data.content.banner,
                experimentalSvgIcons: true,
                bigPlayButton: false,
                errorDisplay: false,
                userActions: { hotkeys: true },
                controlBar: {
                    playToggle: false,
                    pictureInPictureToggle: false,
                    volumePanel: false,
                    fullscreenToggle: false
                },
                sources
            });

            setupPlayerEvents();
            setupPlayerUI();
            restoreProgress();
        };

        const setupPlayerEvents = () => {
            const player = videoPlayer.value;

            // UI events
            player.on('userinactive', () => uiState.value.userActive = false);
            player.on('useractive', () => uiState.value.userActive = true);

            // Playback events
            player.on('play', () => playbackState.value.isPlaying = true);
            player.on('pause', () => playbackState.value.isPlaying = false);
            player.on('waiting', () => playerState.value.loading = true);
            player.on('playing', () => playerState.value.loading = false);

            // Volume events
            player.on('volumechange', () => {
                playbackState.value.volumeLevel = player.volume();
                playbackState.value.isMuted = player.muted();
            });

            // Fullscreen events
            player.on('fullscreenchange', () => {
                playbackState.value.fullscreen = player.isFullscreen();
            });

            // Time update with throttling
            player.on('timeupdate', handleTimeUpdate);
        };

        const handleTimeUpdate = async () => {
            playbackState.value.currentTime = videoPlayer.value.currentTime();
            playbackState.value.duration = videoPlayer.value.duration();

            // Throttle progress updates
            if (Date.now() - lastDataSent.value > PROGRESS_UPDATE_INTERVAL) {
                lastDataSent.value = Date.now();
                if (playbackState.value.currentTime > 1) {
                    await sendCurrentPosition();
                }
            }
        };

        const setupPlayerUI = () => {
            if (vplayerOverlay.value) {
                videoPlayer.value.el().appendChild(vplayerOverlay.value);
            }
            if (skippersRef.value) {
                videoPlayer.value.el().appendChild(skippersRef.value);
            }

            // Mobile fullscreen
            if (isMobile) {
                requestMobileFullscreen();
            }

            // Global access for debugging
            window.videojs = videoPlayer.value;
        };

        const restoreProgress = () => {
            const progress = playerState.value.data.continue_watching?.progress;
            if (progress > 0) {
                videoPlayer.value.currentTime(progress);
            }
        };

        const requestMobileFullscreen = () => {
            try {
                videoPlayer.value.requestFullscreen();
                screen?.orientation?.lock?.('landscape-primary');
            } catch (error) {
                console.warn('Failed to set mobile fullscreen:', error);
            }
        };

        // Control methods
        const togglePlayPause = () => {
            if (playbackState.value.isPlaying) {
                videoPlayer.value.pause();
            } else {
                videoPlayer.value.play();
            }
        };

        const toggleFullscreen = () => {
            if (playbackState.value.fullscreen) {
                videoPlayer.value.exitFullscreen();
            } else {
                videoPlayer.value.requestFullscreen();
            }
        };

        const toggleMute = () => {
            if (playbackState.value.isMuted) {
                videoPlayer.value.muted(false);
                videoPlayer.value.volume(playbackState.value.volumeLevel || 0.5);
            } else {
                videoPlayer.value.muted(true);
            }
        };

        const seekBy = (seconds) => {
            const currentTime = videoPlayer.value.currentTime();
            videoPlayer.value.currentTime(currentTime + seconds);
        };

        const skipIntro = () => {
            const skipTime = playerState.value.data.episode.skip_intro_end;
            videoPlayer.value.currentTime(skipTime);
        };

        // Event handlers
        const handleOverlayClick = (e) => {
            if (e.target === vplayerOverlay.value) {
                togglePlayPause();
            }
        };

        const handleProgressClick = (e) => {
            const rect = e.currentTarget.getBoundingClientRect();
            const percent = (e.clientX - rect.left) / rect.width;
            const newTime = percent * playbackState.value.duration;
            videoPlayer.value.currentTime(newTime);
        };

        const handleVolumeChange = (e) => {
            const rect = e.currentTarget.getBoundingClientRect();
            const percent = Math.max(0, Math.min(1, (rect.bottom - e.clientY) / rect.height));
            videoPlayer.value.volume(percent);
            videoPlayer.value.muted(false);
        };

        // API calls
        const sendCurrentPosition = async () => {
            try {
                await ajax.put(`/watch/${videoId}/progress.json`, {
                    progress: playbackState.value.currentTime,
                    duration: playbackState.value.duration,
                    episode_id: episodeId
                });
            } catch (error) {
                console.warn('Failed to save progress:', error);
            }
        };

        // Watchers
        watch(() => playbackState.value.currentTime, (currentTime) => {
            const episode = playerState.value.data?.episode;
            if (episode?.skip_intro_start && episode?.skip_intro_end) {
                uiState.value.showSkipIntro = currentTime >= episode.skip_intro_start &&
                    currentTime <= episode.skip_intro_end;
            }
        });

        // Lifecycle
        onMounted(async () => {
            document.body.classList.add('prime-video-player');
            await fetchData();
            if (playerState.value.data && !playerState.value.notAvailable) {
                initializePlayer();
            }
        });

        onBeforeUnmount(() => {
            document.body.classList.remove('prime-video-player');

            if (videoPlayer.value) {
                if (videoPlayer.value.isFullscreen()) {
                    videoPlayer.value.exitFullscreen();
                }
                videoPlayer.value.dispose();
                videoPlayer.value = null;
            }

            try {
                screen.orientation?.unlock?.();
            } catch (error) {
                console.warn('Failed to unlock orientation:', error);
            }
        });

        // Render helpers
        const renderNotAvailable = () => (
            <div class="flex flex-col items-center justify-center h-full text-white text-xl p-8">
                <CIcon icon="alert-triangle" size={48} class="mb-4 text-red-500" />
                <span>El contenido no está disponible para su reproducción.</span>
            </div>
        );

        const renderHeader = () => (
            <div class="prime-header flex items-center justify-between p-6">
                <div class="flex items-center gap-4">
                    <router-link to={`/contents/${playerState.value.data.content.id}`} class="prime-back-btn">
                        <CIcon icon="chevron-left" size={24} />
                    </router-link>
                    <div class="prime-title-info">
                        <h1 class="text-xl font-semibold text-white">
                            {playerState.value.data.content.title}
                        </h1>
                        {playerState.value.data.episode && (
                            <span class="text-sm text-white/70">
                                {playerState.value.data.season.title} • {playerState.value.data.episode.title}
                            </span>
                        )}
                    </div>
                </div>
                <div class="flex items-center gap-3">
                    <CIconButton class="prime-control-btn" icon="settings" size={20} />
                    <CIconButton class="prime-control-btn" icon="more-horizontal" size={20} />
                </div>
            </div>
        );

        const renderCenterControls = () => (
            <div class="flex-1 flex items-center justify-center">
                <div class="prime-center-controls flex items-center gap-8">
                    <CIconButton
                        class="prime-seek-btn"
                        icon="rotate-ccw"
                        size={32}
                        onClick={() => seekBy(-10)}
                    />
                    <CIconButton
                        class="prime-play-btn"
                        icon={playbackState.value.isPlaying ? 'pause' : 'play'}
                        size={48}
                        onClick={togglePlayPause}
                    />
                    <CIconButton
                        class="prime-seek-btn"
                        icon="rotate-cw"
                        size={32}
                        onClick={() => seekBy(10)}
                    />
                </div>
            </div>
        );

        const renderProgressBar = () => (
            <div class="prime-progress-container mb-4">
                <div class="prime-progress-bar" onClick={handleProgressClick}>
                    <div class="prime-progress-bg">
                        <div
                            class="prime-progress-fill"
                            style={{ width: `${progressPercentage.value}%` }}
                        >
                            <div class="prime-progress-handle"></div>
                        </div>
                    </div>
                </div>
                <div class="prime-time-info flex justify-between text-sm text-white/80 mt-2">
                    <span>{formatTime(playbackState.value.currentTime)}</span>
                    <span>{formatTime(playbackState.value.duration)}</span>
                </div>
            </div>
        );

        const renderVolumeControls = () => (
            <div
                class="prime-volume-controls flex items-center gap-2"
                onMouseenter={() => uiState.value.showVolumeSlider = true}
                onMouseleave={() => uiState.value.showVolumeSlider = false}
            >
                <CIconButton
                    class="prime-control-small"
                    icon={volumeIcon.value}
                    size={20}
                    onClick={toggleMute}
                />
                {uiState.value.showVolumeSlider && (
                    <div class="prime-volume-slider" onClick={handleVolumeChange}>
                        <div class="prime-volume-bg">
                            <div
                                class="prime-volume-fill"
                                style={{
                                    height: `${(playbackState.value.isMuted ? 0 : playbackState.value.volumeLevel) * 100}%`
                                }}
                            ></div>
                        </div>
                    </div>
                )}
            </div>
        );

        const renderControlBar = () => (
            <div class="prime-control-bar flex items-center justify-between">
                <div class="flex items-center gap-4">
                    <CIconButton
                        class="prime-control-small"
                        icon={playbackState.value.isPlaying ? 'pause' : 'play'}
                        size={20}
                        onClick={togglePlayPause}
                    />
                    {renderVolumeControls()}
                </div>

                <div class="flex items-center gap-4">
                    <CIconButton class="prime-control-small" icon="subtitles" size={20} />
                    <CIconButton class="prime-control-small" icon="settings" size={20} />
                    <CIconButton
                        class="prime-control-small"
                        icon={playbackState.value.fullscreen ? 'minimize' : 'maximize'}
                        size={20}
                        onClick={toggleFullscreen}
                    />
                </div>
            </div>
        );

        const renderSkipIntro = () => (
            playerState.value.data?.episode && uiState.value.showSkipIntro && (
                <div class="absolute right-6 bottom-32">
                    <cButton class="prime-skip-intro" onClick={skipIntro}>
                        {i18n.t('js.video_player.skip_intro') || 'Saltar intro'}
                    </cButton>
                </div>
            )
        );

        // Main render
        return () => (
            <div class="prime-video-container">
                {playerState.value.notAvailable ? (
                    renderNotAvailable()
                ) : (
                    <div class="h-full" v-show={!!playerState.value.data}>
                        <div class={[
                            'prime-video-player',
                            uiState.value.userActive ? 'user-active' : 'user-inactive'
                        ]}>
                            <video
                                ref={videoPlayerRef}
                                id="prime-player"
                                controls
                                preload="auto"
                                class="video-js vjs-default-skin vjs-big-play-centered relative"
                            />

                            <div
                                class="prime-overlay absolute inset-0 flex flex-col"
                                ref={vplayerOverlay}
                                onClick={handleOverlayClick}
                            >
                                {renderHeader()}
                                {renderCenterControls()}

                                <div class="prime-bottom-controls p-6">
                                    {renderProgressBar()}
                                    {renderControlBar()}
                                </div>

                                {renderSkipIntro()}
                            </div>
                        </div>
                    </div>
                )}
            </div>
        );
    }
});