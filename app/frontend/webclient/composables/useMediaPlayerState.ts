import { shallowRef, onBeforeUnmount } from 'vue';

export interface AudioTrackInfo {
    id: number;
    language: string;
    label: string;
    roles: string[];
    channelsCount: number | null;
    active: boolean;
}

export interface MediaPlayerState {
    currentTime: ReturnType<typeof shallowRef<number>>;
    duration: ReturnType<typeof shallowRef<number>>;
    paused: ReturnType<typeof shallowRef<boolean>>;
    playing: ReturnType<typeof shallowRef<boolean>>;
    volume: ReturnType<typeof shallowRef<number>>;
    muted: ReturnType<typeof shallowRef<boolean>>;
    buffering: ReturnType<typeof shallowRef<boolean>>;
    ended: ReturnType<typeof shallowRef<boolean>>;
    isLive: ReturnType<typeof shallowRef<boolean>>;
    seekableStart: ReturnType<typeof shallowRef<number>>;
    seekableEnd: ReturnType<typeof shallowRef<number>>;
    bufferedEnd: ReturnType<typeof shallowRef<number>>;
    playbackRate: ReturnType<typeof shallowRef<number>>;
    variantTracks: ReturnType<typeof shallowRef<any[]>>;
    activeQuality: ReturnType<typeof shallowRef<{ width: number; height: number; bandwidth: number } | null>>;
    audioTracks: ReturnType<typeof shallowRef<AudioTrackInfo[]>>;
    isAutoQuality: ReturnType<typeof shallowRef<boolean>>;
}

export interface MediaPlayerControls {
    play: () => Promise<void>;
    pause: () => void;
    seek: (time: number) => void;
    setVolume: (volume: number) => void;
    toggleMute: () => void;
    setPlaybackRate: (rate: number) => void;
    toggleFullscreen: (element?: HTMLElement) => void;
    selectQuality: (trackId: number) => void;
    enableAutoQuality: () => void;
    selectAudioTrack: (language: string, role?: string) => void;
    togglePictureInPicture: () => Promise<void>;
    goLive: () => void;
}

export type MediaPlayerAPI = MediaPlayerState & MediaPlayerControls & {
    attach: (player: any, video: HTMLVideoElement, eventManager: any) => void;
    detach: () => void;
};

export function useMediaPlayerState(): MediaPlayerAPI {
    const currentTime = shallowRef(0);
    const duration = shallowRef(0);
    const paused = shallowRef(true);
    const playing = shallowRef(false);
    const volume = shallowRef(1);
    const muted = shallowRef(false);
    const buffering = shallowRef(false);
    const ended = shallowRef(false);
    const isLive = shallowRef(false);
    const seekableStart = shallowRef(0);
    const seekableEnd = shallowRef(0);
    const bufferedEnd = shallowRef(0);
    const playbackRate = shallowRef(1);
    const variantTracks = shallowRef<any[]>([]);
    const activeQuality = shallowRef<{ width: number; height: number; bandwidth: number } | null>(null);
    const audioTracks = shallowRef<AudioTrackInfo[]>([]);
    const isAutoQuality = shallowRef(true);

    let videoEl: HTMLVideoElement | null = null;
    let shakaPlayer: any = null;
    let eventManager: any = null;
    let rafId: number | null = null;

    function tick() {
        if (!videoEl) return;
        currentTime.value = videoEl.currentTime;
        ended.value = videoEl.ended;

        if (shakaPlayer) {
            try {
                const seekRange = shakaPlayer.seekRange();
                if (seekRange) {
                    seekableStart.value = seekRange.start;
                    seekableEnd.value = seekRange.end;
                    const d = seekRange.end - seekRange.start;
                    if (d > 0 && isFinite(d)) {
                        duration.value = videoEl.duration && isFinite(videoEl.duration) ? videoEl.duration : d;
                    } else if (videoEl.duration && isFinite(videoEl.duration)) {
                        duration.value = videoEl.duration;
                    }
                } else if (videoEl.duration && isFinite(videoEl.duration)) {
                    duration.value = videoEl.duration;
                }
                const bufferedInfo = shakaPlayer.getBufferedInfo();
                if (bufferedInfo?.video?.length) {
                    bufferedEnd.value = bufferedInfo.video[bufferedInfo.video.length - 1].end;
                }
            } catch (_e) { /* seekRange may throw if not loaded */ }
        } else if (videoEl.duration && isFinite(videoEl.duration)) {
            duration.value = videoEl.duration;
        }

        if (videoEl.buffered.length > 0) {
            bufferedEnd.value = videoEl.buffered.end(videoEl.buffered.length - 1);
        }

        rafId = requestAnimationFrame(tick);
    }

    function startTracking(video: HTMLVideoElement) {
        videoEl = video;
        rafId = requestAnimationFrame(tick);
    }

    function stopTracking() {
        if (rafId !== null) {
            cancelAnimationFrame(rafId);
            rafId = null;
        }
    }

    function attach(player: any, video: HTMLVideoElement, em: any) {
        shakaPlayer = player;
        eventManager = em;
        startTracking(video);

        if (eventManager) {
            eventManager.listen(video, 'play', () => {
                playing.value = true;
                paused.value = false;
            });
            eventManager.listen(video, 'pause', () => {
                playing.value = false;
                paused.value = true;
            });
            eventManager.listen(video, 'ended', () => {
                ended.value = true;
                playing.value = false;
            });
            eventManager.listen(video, 'volumechange', () => {
                volume.value = video.volume;
                muted.value = video.muted;
            });
            eventManager.listen(video, 'ratechange', () => {
                playbackRate.value = video.playbackRate;
            });

            eventManager.listen(player, 'buffering', (event: any) => {
                buffering.value = event.buffering;
            });
            eventManager.listen(player, 'trackschanged', () => {
                variantTracks.value = player.getVariantTracks();
                refreshAudioTracks();
            });
            eventManager.listen(player, 'audiotrackchange', () => {
                refreshAudioTracks();
            });
            eventManager.listen(player, 'adaptation', () => {
                const active = player.getVariantTracks().find((t: any) => t.active);
                if (active) {
                    activeQuality.value = {
                        width: active.width,
                        height: active.height,
                        bandwidth: active.bandwidth,
                    };
                }
            });
            eventManager.listen(player, 'loaded', () => {
                isLive.value = player.isLive();
            });
        } else {
            video.addEventListener('play', () => { playing.value = true; paused.value = false; });
            video.addEventListener('pause', () => { playing.value = false; paused.value = true; });
            video.addEventListener('ended', () => { ended.value = true; playing.value = false; });
            video.addEventListener('volumechange', () => {
                volume.value = video.volume;
                muted.value = video.muted;
            });
            video.addEventListener('ratechange', () => {
                playbackRate.value = video.playbackRate;
            });
        }
    }

    function detach() {
        stopTracking();
        if (eventManager) {
            eventManager.removeAll();
            eventManager = null;
        }
        videoEl = null;
        shakaPlayer = null;
    }

    async function play() {
        try { await videoEl?.play(); } catch (_e) { /* autoplay blocked */ }
    }

    function pause() {
        videoEl?.pause();
    }

    function seek(time: number) {
        if (videoEl) {
            videoEl.currentTime = time;
        }
    }

    function setVolume(v: number) {
        if (videoEl) {
            videoEl.volume = Math.max(0, Math.min(1, v));
            if (v > 0 && videoEl.muted) videoEl.muted = false;
        }
    }

    function toggleMute() {
        if (videoEl) videoEl.muted = !videoEl.muted;
    }

    function setPlaybackRate(rate: number) {
        if (shakaPlayer) {
            shakaPlayer.setPlaybackRate(rate);
        } else if (videoEl) {
            videoEl.playbackRate = rate;
        }
    }

    function toggleFullscreen(element?: HTMLElement) {
        const el = element || videoEl?.parentElement;
        if (!el) return;
        if (document.fullscreenElement) {
            document.exitFullscreen();
        } else {
            el.requestFullscreen();
        }
    }

    function selectQuality(trackId: number) {
        if (!shakaPlayer || !videoEl) return;
        const track = variantTracks.value.find((t: any) => t.id === trackId);
        if (track) {
            const currentTime = videoEl.currentTime;
            shakaPlayer.configure({ abr: { enabled: false } });
            shakaPlayer.selectVariantTrack(track, true);
            videoEl.currentTime = currentTime;
            isAutoQuality.value = false;
            activeQuality.value = { width: track.width, height: track.height, bandwidth: track.bandwidth };
        }
    }

    function selectQualityByBandwidth(bandwidth: number) {
        if (!shakaPlayer || !videoEl) return;
        const tracks = variantTracks.value;
        const activeTrack = tracks.find((t: any) => t.active);
        const currentLang = activeTrack?.language;
        const target = tracks.find((t: any) =>
            t.bandwidth === bandwidth && (!currentLang || t.language === currentLang)
        ) || tracks.find((t: any) => t.bandwidth === bandwidth);
        if (target) {
            const currentTime = videoEl.currentTime;
            shakaPlayer.configure({ abr: { enabled: false } });
            shakaPlayer.selectVariantTrack(target, true);
            videoEl.currentTime = currentTime;
            isAutoQuality.value = false;
            activeQuality.value = { width: target.width, height: target.height, bandwidth: target.bandwidth };
        }
    }

    function enableAutoQuality() {
        if (!shakaPlayer) return;
        shakaPlayer.configure({ abr: { enabled: true } });
        isAutoQuality.value = true;
    }

    async function togglePictureInPicture() {
        if (!videoEl) return;
        if (document.pictureInPictureElement) {
            await document.exitPictureInPicture();
        } else if (videoEl.requestPictureInPicture) {
            await videoEl.requestPictureInPicture();
        }
    }

    function goLive() {
        if (shakaPlayer && shakaPlayer.isLive()) {
            shakaPlayer.goToLive();
        }
    }

    function refreshAudioTracks() {
        if (!shakaPlayer) return;
        try {
            const tracks = shakaPlayer.getAudioTracks();
            audioTracks.value = tracks.map((t: any) => ({
                id: t.id,
                language: t.language || 'und',
                label: t.label || '',
                roles: t.roles || [],
                channelsCount: t.channelsCount || null,
                active: t.active,
            }));
        } catch (_e) { /* getAudioTracks may throw */ }
    }

    function selectAudioTrack(language: string, role?: string) {
        if (!shakaPlayer) return;
        try {
            const tracks = shakaPlayer.getAudioTracks();
            const target = tracks.find((t: any) => {
                const langMatch = t.language === language;
                if (role) {
                    return langMatch && (t.roles || []).includes(role);
                }
                return langMatch;
            });
            if (target) {
                shakaPlayer.selectAudioTrack(target, false);
                refreshAudioTracks();
                if (videoEl && videoEl.paused) {
                    videoEl.play().catch(() => {});
                }
            }
        } catch (_e) { /* selectAudioTrack may throw */ }
    }

    onBeforeUnmount(() => {
        detach();
    });

    return {
        currentTime,
        duration,
        paused,
        playing,
        volume,
        muted,
        buffering,
        ended,
        isLive,
        seekableStart,
        seekableEnd,
        bufferedEnd,
        playbackRate,
        variantTracks,
        activeQuality,
        audioTracks,
        isAutoQuality,
        play,
        pause,
        seek,
        setVolume,
        toggleMute,
        setPlaybackRate,
        toggleFullscreen,
        selectQuality,
        selectQualityByBandwidth,
        enableAutoQuality,
        selectAudioTrack,
        togglePictureInPicture,
        goLive,
        attach,
        detach,
    };
}
