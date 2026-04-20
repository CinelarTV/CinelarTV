import { defineComponent, ref, PropType, watch, onUnmounted } from 'vue';
import CIcon from '../c-icon.vue';

interface Segment {
    id: string | number;
    segment_type: string;
    start_time: number;
    end_time: number | null;
}

interface Episode {
    id: string | number;
    position: number | null;
    title: string;
    thumbnail?: string;
}

export default defineComponent({
    name: 'PlayerNextEpisode',
    props: {
        segments: {
            type: Array as PropType<Segment[]>,
            default: () => []
        },
        currentTime: {
            type: Number,
            required: true
        },
        duration: {
            type: Number,
            default: 0
        },
        nextEpisode: {
            type: Object as PropType<Episode | null>,
            default: null
        },
        onNextEpisode: {
            type: Function as PropType<() => void>,
            required: true
        },
        onCancel: {
            type: Function as PropType<() => void>,
            required: true
        }
    },
    setup(props) {
        const visible = ref(false);
        const countdown = ref(10);
        const countdownInterval = ref<number | null>(null);
        const cancelled = ref(false); // Track if user cancelled

        const NEXT_EPISODE_COUNTDOWN_SECONDS = 10;

        // Reset cancelled state when episode changes
        watch(() => props.nextEpisode?.id, () => {
            cancelled.value = false;
        });

        // Check if we should show next episode button
        watch(() => props.currentTime, (time) => {
            if (!props.nextEpisode) return;
            if (cancelled.value) return; // Don't show if user cancelled

            // Check for next_episode segment
            const nextEpisodeSegment = props.segments.find(seg =>
                seg.segment_type === 'next_episode' &&
                seg.start_time !== null &&
                seg.start_time !== undefined &&
                time >= seg.start_time
            );

            // Also check if we're near the end of the video (last 30 seconds)
            const nearEnd = props.duration > 0 && (props.duration - time) <= 30;

            const shouldShow = nextEpisodeSegment || nearEnd;

            if (shouldShow && !visible.value) {
                visible.value = true;
                startCountdown();
            } else if (!shouldShow && visible.value) {
                hideNextEpisode();
            }
        });

        // Hide when nextEpisode becomes unavailable
        watch(() => props.nextEpisode, (episode) => {
            if (!episode && visible.value) {
                hideNextEpisode();
            }
        });

        const startCountdown = () => {
            countdown.value = NEXT_EPISODE_COUNTDOWN_SECONDS;

            if (countdownInterval.value) {
                clearInterval(countdownInterval.value);
            }

            countdownInterval.value = window.setInterval(() => {
                countdown.value--;
                if (countdown.value <= 0) {
                    clearInterval(countdownInterval.value!);
                    countdownInterval.value = null;
                    props.onNextEpisode();
                }
            }, 1000);
        };

        const hideNextEpisode = () => {
            visible.value = false;
            if (countdownInterval.value) {
                clearInterval(countdownInterval.value);
                countdownInterval.value = null;
            }
        };

        const handleCancel = () => {
            cancelled.value = true; // Mark as cancelled so it doesn't show again
            hideNextEpisode();
            props.onCancel();
        };

        const handleNextNow = () => {
            hideNextEpisode();
            props.onNextEpisode();
        };

        onUnmounted(() => {
            if (countdownInterval.value) {
                clearInterval(countdownInterval.value);
            }
        });

        return () => (
            <div
                class={[
                    'absolute bottom-32 right-4 z-50 transition-all duration-300 ease-out',
                    visible.value ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4 pointer-events-none'
                ]}
            >
                <div class="flex items-center gap-3 bg-zinc-900/95 backdrop-blur-sm rounded-lg shadow-lg shadow-black/30 border border-white/10 px-4 py-3">
                    {/* Mini thumbnail */}
                    {props.nextEpisode?.thumbnail ? (
                        <img
                            src={props.nextEpisode.thumbnail}
                            alt=""
                            class="w-16 h-10 rounded object-cover"
                        />
                    ) : (
                        <div class="w-16 h-10 rounded bg-zinc-700 flex items-center justify-center">
                            <CIcon icon="play" size={14} class="text-white/40" />
                        </div>
                    )}

                    {/* Info */}
                    <div class="flex flex-col min-w-0">
                        <span class="text-white/60 text-xs">
                            Siguiente episodio
                        </span>
                        <span class="text-white text-sm font-medium truncate max-w-[150px]">
                            {props.nextEpisode?.title || 'Episodio siguiente'}
                        </span>
                    </div>

                    {/* Countdown badge */}
                    <div class="flex items-center gap-2">
                        <span class="text-white/80 text-xs font-semibold bg-white/10 px-2 py-1 rounded">
                            {countdown.value}s
                        </span>

                        {/* Play button */}
                        <button
                            onClick={handleNextNow}
                            class="flex items-center justify-center w-9 h-9 bg-white hover:bg-white/90 text-black rounded-md transition-all hover:scale-105 active:scale-95"
                        >
                            <CIcon icon="play" size={16} />
                        </button>

                        {/* Cancel button */}
                        <button
                            onClick={handleCancel}
                            class="flex items-center justify-center w-8 h-8 text-white/60 hover:text-white hover:bg-white/10 rounded-md transition-colors"
                        >
                            <CIcon icon="x" size={16} />
                        </button>
                    </div>
                </div>
            </div>
        );
    }
});
