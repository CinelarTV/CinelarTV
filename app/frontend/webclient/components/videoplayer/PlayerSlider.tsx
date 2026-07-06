import { defineComponent, PropType, computed, ref, nextTick } from "vue";

export default defineComponent({
    name: 'PlayerSlider',
    props: {
        currentTime: {
            type: Number,
            default: 0
        },
        duration: {
            type: Number,
            default: 0
        },
        bufferedEnd: {
            type: Number,
            default: 0
        },
        onSeek: {
            type: Function as PropType<(time: number) => void>,
            required: true
        }
    },
    setup(props) {
        const isDragging = ref(false);
        const dragTime = ref(0);

        const fillPercent = computed(() => {
            if (!props.duration || props.duration === Infinity) return 0;
            const time = isDragging.value ? dragTime.value : props.currentTime;
            return (time / props.duration) * 100;
        });

        const bufferedPercent = computed(() => {
            if (!props.duration || props.duration === Infinity) return 0;
            return (props.bufferedEnd / props.duration) * 100;
        });

        const formatTime = (seconds: number): string => {
            if (!isFinite(seconds)) return '0:00';
            const h = Math.floor(seconds / 3600);
            const m = Math.floor((seconds % 3600) / 60);
            const s = Math.floor(seconds % 60);
            if (h > 0) return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
            return `${m}:${s.toString().padStart(2, '0')}`;
        };

        const previewTime = ref(0);
        const showPreview = ref(false);
        const previewX = ref(0);

        function handleMouseMove(e: MouseEvent) {
            const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
            const x = e.clientX - rect.left;
            const percent = Math.max(0, Math.min(1, x / rect.width));

            previewTime.value = percent * props.duration;
            previewX.value = x;
            showPreview.value = true;

            if (isDragging.value) {
                dragTime.value = previewTime.value;
            }
        }

        function handleMouseDown(e: MouseEvent) {
            const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
            const x = e.clientX - rect.left;
            const percent = Math.max(0, Math.min(1, x / rect.width));
            dragTime.value = percent * props.duration;
            isDragging.value = true;

            const onMove = (ev: MouseEvent) => {
                const dx = ev.clientX - rect.left;
                const p = Math.max(0, Math.min(1, dx / rect.width));
                dragTime.value = p * props.duration;
            };

            const onUp = (ev: MouseEvent) => {
                document.removeEventListener('mousemove', onMove);
                document.removeEventListener('mouseup', onUp);
                props.onSeek(dragTime.value);
                nextTick(() => { isDragging.value = false; });
            };

            document.addEventListener('mousemove', onMove);
            document.addEventListener('mouseup', onUp);
        }

        function handleMouseLeave() {
            showPreview.value = false;
        }

        return () => (
            <div
                class="player-slider group relative inline-flex h-10 w-full cursor-pointer touch-none select-none items-center"
                onMousemove={handleMouseMove}
                onMousedown={handleMouseDown}
                onMouseleave={handleMouseLeave}
            >
                {/* Track */}
                <div class="relative z-0 h-[4px] w-full rounded-full bg-white/[0.16] transition-all duration-200 ease-out group-hover:h-[6px]">
                    {/* Buffered */}
                    <div
                        class="absolute h-full rounded-full bg-white/[0.12] will-change-[width]"
                        style={{ width: `${bufferedPercent.value}%` }}
                    />
                    {/* Fill */}
                    <div
                        class="absolute h-full rounded-full will-change-[width]"
                        style={{
                            width: `${fillPercent.value}%`,
                            background: `var(--c-player-accent-color, #38bdf8)`,
                            boxShadow: showPreview.value ? `0 0 10px var(--c-player-accent-color, #38bdf8)` : 'none'
                        }}
                    />
                </div>

                {/* Thumb */}
                <div
                    class="absolute top-1/2 z-20 h-[14px] w-[14px] -translate-x-1/2 -translate-y-1/2 rounded-full border-2 border-white bg-white opacity-0 transition-all duration-200 ease-out will-change-[left] group-hover:opacity-100 group-active:scale-125"
                    style={{ left: `${fillPercent.value}%` }}
                />

                {/* Preview tooltip */}
                {showPreview.value && props.duration > 0 && !isDragging.value && (
                    <div
                        class="pointer-events-none absolute bottom-full z-30 mb-3 -translate-x-1/2 rounded-lg border border-white/[0.08] bg-black/80 px-2.5 py-1.5 text-xs font-medium tabular-nums text-white shadow-lg backdrop-blur-sm"
                        style={{ left: `${previewX.value}px` }}
                    >
                        {formatTime(previewTime.value)}
                    </div>
                )}
            </div>
        );
    }
});
