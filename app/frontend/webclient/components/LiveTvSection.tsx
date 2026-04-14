import { defineComponent, ref, onMounted, onBeforeUnmount, computed, nextTick } from 'vue';
import { useRouter } from 'vue-router';
import Hls from 'hls.js';
import { ajax } from '@/lib/Ajax';
import { useSiteSettings } from '@/app/services/site-settings';
import CIcon from '@/components/c-icon.vue';

interface LiveChannel {
    id: string;
    name: string;
    logo_url: string | null;
    stream_url: string;
    stream_format: string;
    current_program: {
        title: string;
        description: string | null;
        start_time?: string;
        end_time?: string;
    } | null;
    upcoming_programs?: Array<{
        title: string;
        start_time?: string;
    }>;
}

export default defineComponent({
    name: 'LiveTvSection',
    setup() {
        const router = useRouter();
        const { siteSettings } = useSiteSettings();
        const channels = ref<LiveChannel[]>([]);
        const isLoading = ref(true);
        const activePreviewId = ref<string | null>(null);
        const hoverTimer = ref<number | null>(null);
        const supportsNativeHls = ref(false);
        const previewErrors = ref<Record<string, boolean>>({});
        const previewLoading = ref<Record<string, boolean>>({});
        const previewVideoRefs = ref<Record<string, HTMLVideoElement | null>>({});
        const previewLoadingTimeouts = ref<Record<string, number | null>>({});
        const hlsPreviewInstances = new Map<string, Hls>();

        const isVisible = computed(() =>
            siteSettings?.enable_live_tv && channels.value.length > 0
        );

        const sectionTitle = computed(() =>
            siteSettings?.live_tv_section_title || 'Live TV'
        );

        async function fetchChannels() {
            try {
                const { data } = await ajax.get('/live_tv.json');
                channels.value = data.live_tv_channels || [];
            } catch (err) {
                console.error('Error fetching live TV channels:', err);
                channels.value = [];
            } finally {
                isLoading.value = false;
            }
        }

        function watchChannel(channelId: string) {
            router.push({ name: 'live_tv.watch', params: { id: channelId } });
        }

        function viewAll() {
            router.push({ name: 'live_tv.index' });
        }

        function clearHoverTimer() {
            if (hoverTimer.value !== null) {
                window.clearTimeout(hoverTimer.value);
                hoverTimer.value = null;
            }
        }

        function setPreviewVideoRef(channelId: string, el: HTMLVideoElement | null) {
            previewVideoRefs.value[channelId] = el;
        }

        function setPreviewLoading(channelId: string, value: boolean) {
            previewLoading.value[channelId] = value;

            const currentTimeout = previewLoadingTimeouts.value[channelId];
            if (currentTimeout) {
                window.clearTimeout(currentTimeout);
                previewLoadingTimeouts.value[channelId] = null;
            }

            // Safety net: if stream stalls silently, stop showing spinner after a few seconds.
            if (value) {
                previewLoadingTimeouts.value[channelId] = window.setTimeout(() => {
                    previewLoading.value[channelId] = false;
                    previewLoadingTimeouts.value[channelId] = null;
                }, 4500);
            }
        }

        function bindPreviewVideoEvents(video: HTMLVideoElement, channelId: string) {
            video.onloadedmetadata = () => setPreviewLoading(channelId, false);
            video.onloadeddata = () => setPreviewLoading(channelId, false);
            video.oncanplay = () => setPreviewLoading(channelId, false);
            video.onplaying = () => setPreviewLoading(channelId, false);
            video.onwaiting = () => setPreviewLoading(channelId, true);
            video.onstalled = () => setPreviewLoading(channelId, true);
            video.onerror = () => {
                markPreviewError(channelId);
                destroyPreviewInstance(channelId);
            };
        }

        function destroyPreviewInstance(channelId: string) {
            const hls = hlsPreviewInstances.get(channelId);
            if (hls) {
                hls.destroy();
                hlsPreviewInstances.delete(channelId);
            }
            const video = previewVideoRefs.value[channelId];
            if (video) {
                video.pause();
                video.onloadedmetadata = null;
                video.onloadeddata = null;
                video.oncanplay = null;
                video.onplaying = null;
                video.onwaiting = null;
                video.onstalled = null;
                video.onerror = null;
                video.removeAttribute('src');
                video.load();
            }
            setPreviewLoading(channelId, false);
        }

        function canPreview(channel: LiveChannel) {
            if (!channel.stream_url || previewErrors.value[channel.id]) return false;
            if (channel.stream_format === 'external') return true;
            if (channel.stream_format === 'hls') return supportsNativeHls.value || Hls.isSupported();
            return false;
        }

        async function attachPreviewStream(channel: LiveChannel) {
            const video = previewVideoRefs.value[channel.id];
            if (!video) return;

            setPreviewLoading(channel.id, true);
            bindPreviewVideoEvents(video, channel.id);

            if (channel.stream_format === 'hls') {
                if (supportsNativeHls.value) {
                    video.src = channel.stream_url;
                } else if (Hls.isSupported()) {
                    destroyPreviewInstance(channel.id);
                    const hls = new Hls({
                        enableWorker: true,
                        lowLatencyMode: true,
                        backBufferLength: 0,
                        maxBufferLength: 8,
                    });
                    hls.on(Hls.Events.ERROR, (_, data) => {
                        if (data.fatal) {
                            markPreviewError(channel.id);
                            destroyPreviewInstance(channel.id);
                        }
                    });
                    hls.loadSource(channel.stream_url);
                    hls.attachMedia(video);
                    hlsPreviewInstances.set(channel.id, hls);
                }
            } else {
                video.src = channel.stream_url;
            }

            try {
                await video.play();
                setPreviewLoading(channel.id, false);
            } catch {
                markPreviewError(channel.id);
            }
        }

        function startPreview(channel: LiveChannel) {
            if (!window.matchMedia('(hover: hover)').matches) return;

            clearHoverTimer();
            hoverTimer.value = window.setTimeout(async () => {
                if (!canPreview(channel)) {
                    activePreviewId.value = null;
                    setPreviewLoading(channel.id, false);
                    return;
                }

                if (activePreviewId.value && activePreviewId.value !== channel.id) {
                    destroyPreviewInstance(activePreviewId.value);
                }

                activePreviewId.value = channel.id;
                setPreviewLoading(channel.id, true);
                await nextTick();
                await attachPreviewStream(channel);
            }, 220);
        }

        function stopPreview() {
            clearHoverTimer();
            if (activePreviewId.value) {
                destroyPreviewInstance(activePreviewId.value);
            }
            activePreviewId.value = null;
        }

        function markPreviewError(channelId: string) {
            previewErrors.value[channelId] = true;
            setPreviewLoading(channelId, false);
            if (activePreviewId.value === channelId) {
                activePreviewId.value = null;
            }
        }

        function formatStartTime(value?: string) {
            if (!value) return '';
            const date = new Date(value);
            if (Number.isNaN(date.getTime())) return '';
            return date.toLocaleTimeString('es-ES', { hour: '2-digit', minute: '2-digit' });
        }

        onMounted(() => {
            const probe = document.createElement('video');
            supportsNativeHls.value = probe.canPlayType('application/vnd.apple.mpegurl') !== '';

            if (siteSettings?.enable_live_tv) {
                fetchChannels();
            }
        });

        onBeforeUnmount(() => {
            clearHoverTimer();

            Object.keys(previewLoadingTimeouts.value).forEach((channelId) => {
                const timeoutId = previewLoadingTimeouts.value[channelId];
                if (timeoutId) {
                    window.clearTimeout(timeoutId);
                }
            });

            for (const channelId of Object.keys(previewVideoRefs.value)) {
                destroyPreviewInstance(channelId);
            }
        });

        return () => {
            if (!isVisible.value || isLoading.value) {
                return null;
            }

            return (
                <section class="py-6 live-tv-rail">
                    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
                        <div class="live-tv-rail__header mb-4 flex items-center justify-between">
                            <div class="flex items-center gap-2.5">
                                <div class="h-3 w-3 animate-pulse rounded-full bg-red-600"></div>
                                <h2 class="text-xl font-bold text-white">{sectionTitle.value}</h2>
                                <span class="live-tv-rail__count rounded bg-red-600 px-2 py-0.5 text-xs font-semibold text-white">
                                    {channels.value.length}
                                </span>
                            </div>
                            <button
                                onClick={viewAll}
                                class="live-tv-rail__view-all flex items-center gap-1 text-sm text-white/60 transition-colors hover:text-white"
                            >
                                Ver todo
                                <CIcon icon="chevron-right" size={16} />
                            </button>
                        </div>

                        <div class="live-tv-rail__track flex gap-4 overflow-x-auto scrollbar-hide">
                            {channels.value.map((channel, index) => {
                                const nextProgram = channel.upcoming_programs?.[0] || null;
                                const isPreviewActive = activePreviewId.value === channel.id;
                                const isPreviewLoading = !!previewLoading.value[channel.id];

                                return (
                                    <button
                                        key={channel.id}
                                        onClick={() => watchChannel(channel.id)}
                                        onMouseenter={() => startPreview(channel)}
                                        onMouseleave={stopPreview}
                                        onFocus={() => startPreview(channel)}
                                        onBlur={stopPreview}
                                        class="live-tv-rail__card group"
                                        aria-label={`Ver canal ${channel.name}`}
                                    >
                                        <div class="live-tv-rail__card-shell relative overflow-hidden rounded-xl">
                                            <div class="live-tv-rail__backdrop" />
                                            <div class="live-tv-rail__logo flex aspect-video items-center justify-center p-4">
                                                {isPreviewActive && canPreview(channel) && (
                                                    <video
                                                        class="live-tv-rail__video-preview"
                                                        ref={(el) => setPreviewVideoRef(channel.id, el as HTMLVideoElement | null)}
                                                        muted
                                                        autoplay
                                                        loop
                                                        playsinline
                                                        preload="none"
                                                    />
                                                )}

                                                <div class={[
                                                    'live-tv-rail__preview-loader',
                                                    isPreviewActive && isPreviewLoading && 'is-visible'
                                                ]}>
                                                    <span class="live-tv-rail__preview-spinner" />
                                                </div>

                                                {channel.logo_url ? (
                                                    <img
                                                        src={channel.logo_url}
                                                        alt={channel.name}
                                                        class={[
                                                            'live-tv-rail__logo-image',
                                                            isPreviewActive && isPreviewLoading && 'is-preview-loading',
                                                            isPreviewActive && !isPreviewLoading && 'is-preview-ready',
                                                            'h-full w-full object-contain'
                                                        ]}
                                                        loading="lazy"
                                                    />
                                                ) : (
                                                    <CIcon icon="broadcast" size={32} class="text-white/30" />
                                                )}
                                            </div>

                                            <div class="live-tv-rail__live absolute right-2 top-2 flex items-center gap-1 rounded bg-red-600 px-1.5 py-0.5 text-[10px] font-bold uppercase text-white">
                                                <div class="h-1 w-1 animate-pulse rounded-full bg-white"></div>
                                                LIVE
                                            </div>

                                            <div class="live-tv-rail__meta p-2.5">
                                                <p class="truncate text-xs font-semibold text-white">{channel.name}</p>
                                                {channel.current_program && (
                                                    <p class="mt-0.5 line-clamp-1 text-[10px] text-white/50">
                                                        {channel.current_program.title}
                                                    </p>
                                                )}
                                            </div>

                                            <div class="live-tv-rail__preview">
                                                <p class="live-tv-rail__preview-kicker">Canal {index + 1}</p>
                                                <h3 class="live-tv-rail__preview-title">{channel.name}</h3>
                                                {channel.current_program ? (
                                                    <>
                                                        <p class="live-tv-rail__preview-now">En vivo: {channel.current_program.title}</p>
                                                        {channel.current_program.description && (
                                                            <p class="live-tv-rail__preview-description line-clamp-2">
                                                                {channel.current_program.description}
                                                            </p>
                                                        )}
                                                    </>
                                                ) : (
                                                    <p class="live-tv-rail__preview-description">Sin programa en vivo por ahora.</p>
                                                )}

                                                {nextProgram && (
                                                    <p class="live-tv-rail__preview-next">
                                                        Sigue {formatStartTime(nextProgram.start_time)} · {nextProgram.title}
                                                    </p>
                                                )}

                                                <span class="live-tv-rail__preview-cta">Ver canal</span>
                                            </div>
                                        </div>
                                    </button>
                                );
                            })}
                        </div>
                    </div>
                </section>
            );
        };
    }
});
