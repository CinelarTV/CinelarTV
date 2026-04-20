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

        // Skip segment types that should show the skip button
        const skipTypes = ['skip_intro', 'skip_resume'];

        // Check if current time is within a skippable segment
        watch(() => props.currentTime, (time) => {
            const segment = props.segments.find(seg => {
                if (!skipTypes.includes(seg.segment_type)) return false;
                if (seg.start_time === null || seg.start_time === undefined) return false;
                if (seg.end_time === null || seg.end_time === undefined) return false;
                return time >= seg.start_time && time < seg.end_time;
            });

            if (segment && !visible.value) {
                // Just entered a skip segment
                visible.value = true;
                activeSegment.value = segment;
            } else if (!segment && visible.value) {
                // Left the skip segment
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
                    'absolute bottom-32 right-4 z-50 transition-all duration-300 ease-out',
                    visible.value ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4 pointer-events-none'
                ]}
            >
                <button
                    onClick={handleSkip}
                    class="flex items-center gap-2 px-5 py-3 bg-white/95 hover:bg-white text-black font-semibold rounded-lg shadow-lg shadow-black/30 backdrop-blur-sm transition-all hover:scale-105 active:scale-95"
                >
                    <span class="text-sm tracking-wide">{segmentLabel.value}</span>
                    <CIcon icon="fast-forward" size={18} />
                </button>
            </div>
        );
    }
});
