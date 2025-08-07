import { defineComponent, ref, onMounted, onBeforeUnmount, inject, watch, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { ajax } from '../lib/Ajax';
import videojs from 'video.js';
import 'video.js/dist/video-js.css';
import { useHead } from 'unhead';
import { toast } from 'vue3-toastify';

import CIconButton from '../components/forms/c-icon-button.vue';
import CIcon from "../components/c-icon.vue";
import cButton from "../components/forms/c-button";

export default defineComponent({
    name: 'PrimeVideoPlayer',
    setup() {
        const SiteSettings = inject('SiteSettings');
        const currentUser = inject('currentUser');
        const i18n = inject('I18n');
        const isMobile = inject('isMobile');
        const data = ref<any>(null);
        const videoPlayer = ref<any>(null);
        const videoPlayerRef = ref<any>(null);
        const userActive = ref(true);
        const isPlaying = ref(false);
        const loading = ref(true);
        const lastDataSent = ref(0);
        const fullscreen = ref(false);
        const currentPlayback = ref({ currentTime: 0, duration: 0 });
        const showSkipIntro = ref(false);
        const vplayerOverlay = ref<any>(null);
        const skippersRef = ref<any>(null);
        const isDragging = ref(false);
        const volumeLevel = ref(1);
        const isMuted = ref(false);
        const showVolumeSlider = ref(false);
        const route = useRoute();
        const router = useRouter();
        const videoId = route.params.id;
        const episodeId = route.params.episodeId;

        // Computed para el progreso
        const progressPercentage = computed(() => {
            if (!currentPlayback.value.duration) return 0;
            return (currentPlayback.value.currentTime / currentPlayback.value.duration) * 100;
        });

        // Formatear tiempo
        const formatTime = (seconds: number) => {
            if (!seconds || isNaN(seconds)) return '0:00';
            const h = Math.floor(seconds / 3600);
            const m = Math.floor((seconds % 3600) / 60);
            const s = Math.floor(seconds % 60);
            if (h > 0) {
                return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
            }
            return `${m}:${s.toString().padStart(2, '0')}`;
        };

        const fetchData = async () => {
            try {
                let url = episodeId ? `/watch/${videoId}/${episodeId}.json` : `/watch/${videoId}.json`;
                const response = await ajax.get(url);
                data.value = response.data.data;
                // Redirección si es necesario
                if (data.value.content.content_type === 'TVSHOW' && !(route.params.episodeId || data.value.episode?.id)) {
                    const firstEpisode = data.value.season.episodes[0];
                    if (firstEpisode) return router.replace(`/watch/${videoId}/${firstEpisode.id}`);
                } else if (!route.params.episodeId && data.value.episode?.id) {
                    return router.replace(`/watch/${videoId}/${data.value.episode.id}`);
                }
            } catch (error: any) {
                if (error.response?.errors?.[0]?.error_type === 'content_not_available') {
                    toast.error('Contenido no disponible');
                }
                toast.error('Error al cargar el video.');
            }
        };

        const getVideoType = (url: string) => {
            const extension = url.split('.').pop();
            switch (extension) {
                case 'mp4': return 'video/mp4';
                case 'm3u8': return 'application/x-mpegURL';
                default: return 'video/mp4';
            }
        };

        onMounted(async () => {
            document.body.classList.add('prime-video-player');
            await fetchData();
            useHead({ title: data.value?.content?.title });
            videoPlayer.value = videojs(videoPlayerRef.value, {
                autoplay: true,
                preload: 'auto',
                responsive: true,
                fill: true,
                inactivityTimeout: route.query.debug ? 0 : 3000,
                poster: data.value.content.banner,
                experimentalSvgIcons: true,
                bigPlayButton: false,
                errorDisplay: false,
                userActions: { hotkeys: true },
                controlBar: { playToggle: false, pictureInPictureToggle: false, volumePanel: false, fullscreenToggle: false },
                sources: data.value.sources.map((source: any) => ({
                    src: source.url,
                    type: getVideoType(source.url)
                }))
            });

            // Restaurar progreso
            const { progress } = data.value.continue_watching || {};
            if (progress > 0) videoPlayer.value.currentTime(progress);

            // Overlay y skippers
            videoPlayer.value.el().appendChild(vplayerOverlay.value);
            if (skippersRef.value) videoPlayer.value.el().appendChild(skippersRef.value);

            // Eventos
            videoPlayer.value.on('userinactive', () => userActive.value = false);
            videoPlayer.value.on('useractive', () => userActive.value = true);
            videoPlayer.value.on('play', () => isPlaying.value = true);
            videoPlayer.value.on('pause', () => isPlaying.value = false);
            videoPlayer.value.on('waiting', () => loading.value = true);
            videoPlayer.value.on('playing', () => loading.value = false);
            videoPlayer.value.on('fullscreenchange', () => fullscreen.value = !fullscreen.value);
            videoPlayer.value.on('volumechange', () => {
                volumeLevel.value = videoPlayer.value.volume();
                isMuted.value = videoPlayer.value.muted();
            });
            videoPlayer.value.on('timeupdate', async () => {
                currentPlayback.value.currentTime = videoPlayer.value?.currentTime();
                currentPlayback.value.duration = videoPlayer.value?.duration();
                if (Date.now() - lastDataSent.value > 5000) {
                    lastDataSent.value = Date.now();
                    if (videoPlayer.value.currentTime() > 1) await sendCurrentPosition();
                }
            });

            window.videojs = videoPlayer.value;

            // Modo móvil
            if (isMobile) {
                try {
                    videoPlayer.value.requestFullscreen();
                    if (screen?.orientation?.lock) screen.orientation.lock('landscape-primary');
                } catch { }
            }
        });

        watch(currentPlayback, (newVal) => {
            if (data.value?.episode?.skip_intro_start && data.value?.episode?.skip_intro_end) {
                showSkipIntro.value = newVal.currentTime >= data.value.episode.skip_intro_start && newVal.currentTime <= data.value.episode.skip_intro_end;
            }
        });

        onBeforeUnmount(() => {
            document.body.classList.remove('prime-video-player');
            if (videoPlayer.value?.isFullscreen()) videoPlayer.value.exitFullscreen();
            try { screen.orientation.unlock(); } catch { }
            videoPlayer.value?.dispose();
            videoPlayer.value = null;
        });

        // Métodos de control
        const handleOverlayClick = (e: MouseEvent) => {
            if (e.target === vplayerOverlay.value) togglePlayPause();
        };

        const toggleFullscreen = () => {
            if (videoPlayer.value.isFullscreen()) videoPlayer.value.exitFullscreen();
            else videoPlayer.value.requestFullscreen();
        };

        const togglePlayPause = () => {
            if (isPlaying.value) videoPlayer.value.pause();
            else videoPlayer.value.play();
        };

        const sendCurrentPosition = async () => {
            try {
                await ajax.put(`/watch/${videoId}/progress.json`, {
                    progress: videoPlayer.value.currentTime(),
                    duration: videoPlayer.value.duration(),
                    episode_id: episodeId
                });
            } catch { }
        };

        const skipIntro = () => {
            videoPlayer.value.currentTime(data.value.episode.skip_intro_end);
        };

        const seekBy = (seconds: number) => {
            videoPlayer.value.currentTime(videoPlayer.value.currentTime() + seconds);
        };

        const handleProgressClick = (e: MouseEvent) => {
            const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
            const percent = (e.clientX - rect.left) / rect.width;
            const newTime = percent * currentPlayback.value.duration;
            videoPlayer.value.currentTime(newTime);
        };

        const toggleMute = () => {
            if (isMuted.value) {
                videoPlayer.value.muted(false);
                videoPlayer.value.volume(volumeLevel.value || 0.5);
            } else {
                videoPlayer.value.muted(true);
            }
        };

        const handleVolumeChange = (e: MouseEvent) => {
            const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
            const percent = Math.max(0, Math.min(1, (rect.bottom - e.clientY) / rect.height));
            videoPlayer.value.volume(percent);
            videoPlayer.value.muted(false);
        };

        // Render
        return () => (
            <div class="prime-video-container" v-show={!!data.value}>
                <div class={['prime-video-player', userActive.value ? 'user-active' : 'user-inactive']}>
                    <video ref={videoPlayerRef} id="prime-player" controls preload="auto" class="video-js vjs-default-skin vjs-big-play-centered relative" />

                    {/* Prime Video Overlay */}
                    <div
                        class="prime-overlay absolute inset-0 flex flex-col"
                        ref={vplayerOverlay}
                        onClick={handleOverlayClick}
                    >
                        {/* Header */}
                        <div class="prime-header flex items-center justify-between p-6">
                            <div class="flex items-center gap-4">
                                <router-link to={`/contents/${data.value?.content.id}`} class="prime-back-btn">
                                    <CIcon icon="chevron-left" size={24} />
                                </router-link>
                                <div class="prime-title-info">
                                    <h1 class="text-xl font-semibold text-white">{data.value?.content?.title}</h1>
                                    {data.value?.episode && (
                                        <span class="text-sm text-white/70">{data.value.season.title} • {data.value.episode.title}</span>
                                    )}
                                </div>
                            </div>
                            <div class="flex items-center gap-3">
                                <CIconButton class="prime-control-btn" icon="settings" size={20} />
                                <CIconButton class="prime-control-btn" icon="more-horizontal" size={20} />
                            </div>
                        </div>

                        {/* Center Play Controls */}
                        <div class="flex-1 flex items-center justify-center">
                            <div class="prime-center-controls flex items-center gap-8">
                                <CIconButton class="prime-seek-btn" icon="rotate-ccw" size={32} onClick={() => seekBy(-10)} />
                                <CIconButton class="prime-play-btn" icon={isPlaying.value ? 'pause' : 'play'} size={48} onClick={togglePlayPause} />
                                <CIconButton class="prime-seek-btn" icon="rotate-cw" size={32} onClick={() => seekBy(10)} />
                            </div>
                        </div>

                        {/* Bottom Controls */}
                        <div class="prime-bottom-controls p-6">
                            {/* Progress Bar */}
                            <div class="prime-progress-container mb-4">
                                <div class="prime-progress-bar" onClick={handleProgressClick}>
                                    <div class="prime-progress-bg">
                                        <div class="prime-progress-fill" style={{ width: `${progressPercentage.value}%` }}>
                                            <div class="prime-progress-handle"></div>
                                        </div>
                                    </div>
                                </div>
                                <div class="prime-time-info flex justify-between text-sm text-white/80 mt-2">
                                    <span>{formatTime(currentPlayback.value.currentTime)}</span>
                                    <span>{formatTime(currentPlayback.value.duration)}</span>
                                </div>
                            </div>

                            {/* Control Bar */}
                            <div class="prime-control-bar flex items-center justify-between">
                                <div class="flex items-center gap-4">
                                    <CIconButton class="prime-control-small" icon={isPlaying.value ? 'pause' : 'play'} size={20} onClick={togglePlayPause} />
                                    <div class="prime-volume-controls flex items-center gap-2"
                                        onMouseenter={() => showVolumeSlider.value = true}
                                        onMouseleave={() => showVolumeSlider.value = false}>
                                        <CIconButton class="prime-control-small"
                                            icon={isMuted.value ? 'volume-x' : volumeLevel.value < 0.5 ? 'volume1' : 'volume2'}
                                            size={20}
                                            onClick={toggleMute} />
                                        {showVolumeSlider.value && (
                                            <div class="prime-volume-slider" onClick={handleVolumeChange}>
                                                <div class="prime-volume-bg">
                                                    <div class="prime-volume-fill" style={{ height: `${(isMuted.value ? 0 : volumeLevel.value) * 100}%` }}></div>
                                                </div>
                                            </div>
                                        )}
                                    </div>
                                </div>

                                <div class="flex items-center gap-4">
                                    <CIconButton class="prime-control-small" icon="subtitles" size={20} />
                                    <CIconButton class="prime-control-small" icon="settings" size={20} />
                                    <CIconButton class="prime-control-small" icon={fullscreen.value ? 'minimize' : 'maximize'} size={20} onClick={toggleFullscreen} />
                                </div>
                            </div>
                        </div>

                        {/* Skip Intro Button */}
                        {data.value?.episode && showSkipIntro.value && (
                            <div class="absolute right-6 bottom-32">
                                <cButton class="prime-skip-intro" onClick={skipIntro}>
                                    {i18n.t('js.video_player.skip_intro') || 'Saltar intro'}
                                </cButton>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        );
    }
});