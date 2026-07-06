import { defineComponent, PropType, computed, ref, nextTick } from "vue";
import CIcon from "../c-icon.vue";

export default defineComponent({
    name: 'PlayerVolumeSlider',
    props: {
        volume: {
            type: Number,
            default: 1
        },
        muted: {
            type: Boolean,
            default: false
        },
        onVolumeChange: {
            type: Function as PropType<(volume: number) => void>,
            required: true
        },
        onToggleMute: {
            type: Function as PropType<() => void>,
            required: true
        }
    },
    setup(props) {
        const isDragging = ref(false);
        const dragVolume = ref(props.volume);

        const ICONS = {
            muted: "volume-x",
            low: "volume1",
            high: "volume2"
        };

        const currentIcon = computed(() => {
            if (props.muted || props.volume === 0) return ICONS.muted;
            if (props.volume < 0.7) return ICONS.low;
            return ICONS.high;
        });

        const volumePercent = computed(() => {
            const v = isDragging.value ? dragVolume.value : props.volume;
            return v * 100;
        });

        function handleMouseDown(e: MouseEvent) {
            const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
            const updateVolume = (ev: MouseEvent) => {
                const x = ev.clientX - rect.left;
                const percent = Math.max(0, Math.min(1, x / rect.width));
                dragVolume.value = percent;
            };

            updateVolume(e);
            isDragging.value = true;

            const onMove = (ev: MouseEvent) => updateVolume(ev);
            const onUp = (ev: MouseEvent) => {
                document.removeEventListener('mousemove', onMove);
                document.removeEventListener('mouseup', onUp);
                updateVolume(ev);
                props.onVolumeChange(dragVolume.value);
                nextTick(() => { isDragging.value = false; });
            };

            document.addEventListener('mousemove', onMove);
            document.addEventListener('mouseup', onUp);
        }

        return () => (
            <div class="flex items-center gap-2.5 w-[180px]">
                <button
                    onClick={props.onToggleMute}
                    class="player-control-btn player-control-btn--sm flex-shrink-0"
                >
                    <CIcon icon={currentIcon.value} size={16} />
                </button>
                <div
                    class="volume-slider group relative inline-flex h-10 w-full max-w-[80px] cursor-pointer touch-none select-none items-center"
                    onMousedown={handleMouseDown}
                >
                    {/* Track */}
                    <div class="relative z-0 h-[4px] w-full rounded-full bg-white/[0.16] transition-all duration-200 ease-out group-hover:h-[6px]">
                        <div
                            class="absolute h-full rounded-full will-change-[width]"
                            style={{
                                width: `${volumePercent.value}%`,
                                background: `var(--c-player-accent-color, #38bdf8)`
                            }}
                        />
                    </div>
                    {/* Thumb */}
                    <div
                        class="absolute top-1/2 z-20 h-[14px] w-[14px] -translate-x-1/2 -translate-y-1/2 rounded-full border-2 border-white bg-white opacity-0 transition-all duration-200 ease-out will-change-[left] group-hover:opacity-100 group-active:scale-125"
                        style={{ left: `${volumePercent.value}%` }}
                    />
                </div>
            </div>
        );
    }
});
