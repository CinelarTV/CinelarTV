import { defineComponent, ref, computed, PropType, watch } from 'vue';
import CIcon from '../c-icon.vue';

interface Segment {
    id: string | number;
    segment_type: string;
    start_time: number;
    end_time: number;
}

export default defineComponent({
    name: 'PlayerSkipButton',
    props: {
        segments: {
            type: Array as PropType<Segment[]>,
            default: () => []
        },
        currentTime: {
            type: Number,
            required: true
        },
        onSkip: {
            type: Function as PropType<(endTime: number) => void>,
            required: true
        }
    },
    setup(props) {
        const visible = ref(false);
        const activeSegment = ref<Segment | null>(null);

        const skipTypes = ['skip_intro', 'skip_resume'];

        watch(() => props.currentTime, (time) => {
            const segment = props.segments.find(seg => {
                if (!skipTypes.includes(seg.segment_type)) return false;
                if (seg.start_time === null || seg.start_time === undefined) return false;
                if (seg.end_time === null || seg.end_time === undefined) return false;
                return time >= seg.start_time && time < seg.end_time;
            });

            if (segment && !visible.value) {
                visible.value = true;
                activeSegment.value = segment;
            } else if (!segment && visible.value) {
                visible.value = false;
                activeSegment.value = null;
            }
        }, { immediate: true });

        const handleSkip = () => {
            if (activeSegment.value?.end_time !== undefined) {
                props.onSkip(activeSegment.value.end_time);
                visible.value = false;
            }
        };

        const segmentLabel = computed(() => {
            if (!activeSegment.value) return '';
            switch (activeSegment.value.segment_type) {
                case 'skip_intro':
                    return 'Omitir intro';
                case 'skip_resume':
                    return 'Omitir resumen';
                default:
                    return 'Omitir';
            }
        });

        return () => (
            <div
                class={[
                    'absolute bottom-32 right-5 z-50 transition-all duration-350 ease-out',
                    visible.value
                        ? 'opacity-100 translate-y-0'
                        : 'opacity-0 translate-y-3 pointer-events-none'
                ]}
            >
                <button
                    onClick={handleSkip}
                    class="player-skip-btn flex items-center gap-2.5 px-5 py-3 bg-white/[0.92] hover:bg-white text-black font-semibold rounded-2xl shadow-lg shadow-black/30 backdrop-blur-md border border-white/20 transition-all duration-200 ease-out hover:scale-[1.04] active:scale-[0.96] cursor-pointer outline-none focus-visible:ring-2 focus-visible:ring-[var(--c-player-accent-color,#38bdf8)]"
                >
                    <span class="text-sm tracking-wide">{segmentLabel.value}</span>
                    <CIcon icon="fast-forward" size={16} />
                </button>
            </div>
        );
    }
});
