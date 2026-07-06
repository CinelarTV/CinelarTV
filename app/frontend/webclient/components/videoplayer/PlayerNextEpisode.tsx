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
        const cancelled = ref(false);

        const NEXT_EPISODE_COUNTDOWN_SECONDS = 10;

        watch(() => props.nextEpisode?.id, () => {
            cancelled.value = false;
        });

        watch(() => props.currentTime, (time) => {
            if (!props.nextEpisode) return;
            if (cancelled.value) return;

            const nextEpisodeSegment = props.segments.find(seg =>
                seg.segment_type === 'next_episode' &&
                seg.start_time !== null &&
                seg.start_time !== undefined &&
                time >= seg.start_time
            );

            const nearEnd = props.duration > 0 && (props.duration - time) <= 30;
            const shouldShow = nextEpisodeSegment || nearEnd;

            if (shouldShow && !visible.value) {
                visible.value = true;
                startCountdown();
            } else if (!shouldShow && visible.value) {
                hideNextEpisode();
            }
        });

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
            cancelled.value = true;
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
                    'absolute bottom-32 right-5 z-50 transition-all duration-400 ease-out',
                    visible.value
                        ? 'opacity-100 translate-y-0'
                        : 'opacity-0 translate-y-3 pointer-events-none'
                ]}
            >
                <div class="next-episode-card flex items-center gap-3.5 bg-[var(--c-surface-2,rgba(255,255,255,0.05))] backdrop-blur-2xl rounded-2xl shadow-xl shadow-black/40 border border-white/[0.08] px-4 py-3">
                    {/* Thumbnail */}
                    {props.nextEpisode?.thumbnail ? (
                        <img
                            src={props.nextEpisode.thumbnail}
                            alt=""
                            class="w-[4.5rem] h-[2.75rem] rounded-xl object-cover flex-shrink-0"
                        />
                    ) : (
                        <div class="w-[4.5rem] h-[2.75rem] rounded-xl bg-white/[0.08] flex items-center justify-center flex-shrink-0">
                            <CIcon icon="play" size={14} class="text-white/30" />
                        </div>
                    )}

                    {/* Info */}
                    <div class="flex flex-col min-w-0 gap-0.5">
                        <span class="text-[0.65rem] font-semibold uppercase tracking-wider text-white/40">
                            Siguiente episodio
                        </span>
                        <span class="text-white text-sm font-medium truncate max-w-[160px]">
                            {props.nextEpisode?.title || 'Episodio siguiente'}
                        </span>
                    </div>

                    {/* Actions */}
                    <div class="flex items-center gap-2 ml-1">
                        {/* Countdown */}
                        <span class="text-white/70 text-xs font-semibold tabular-nums bg-white/[0.08] px-2 py-1 rounded-lg">
                            {countdown.value}s
                        </span>

                        {/* Play now */}
                        <button
                            onClick={handleNextNow}
                            class="flex items-center justify-center w-9 h-9 bg-white hover:bg-white/90 text-black rounded-xl transition-all duration-200 ease-out hover:scale-105 active:scale-95 cursor-pointer outline-none focus-visible:ring-2 focus-visible:ring-[var(--c-player-accent-color,#38bdf8)]"
                        >
                            <CIcon icon="play" size={15} />
                        </button>

                        {/* Cancel */}
                        <button
                            onClick={handleCancel}
                            class="player-control-btn player-control-btn--sm"
                        >
                            <CIcon icon="x" size={14} />
                        </button>
                    </div>
                </div>
            </div>
        );
    }
});
