import { defineComponent, PropType, onMounted, onBeforeUnmount } from "vue";

export default defineComponent({
    name: "PlayerGestures",
    props: {
        videoRef: {
            type: Function as PropType<() => HTMLVideoElement | null>,
            required: true
        },
        onTogglePlay: {
            type: Function as PropType<() => void>,
            required: true
        },
        onSeek: {
            type: Function as PropType<(delta: number) => void>,
            required: true
        },
        onToggleFullscreen: {
            type: Function as PropType<() => void>,
            required: true
        },
        onToggleControls: {
            type: Function as PropType<() => void>,
            required: true
        }
    },
    setup(props) {
        let lastTap = 0;
        let lastTapX = 0;

        function handlePointerUp(e: PointerEvent) {
            const video = props.videoRef();
            if (!video) return;

            const now = Date.now();
            const rect = (e.currentTarget as HTMLElement).getBoundingClientRect();
            const x = e.clientX - rect.left;
            const width = rect.width;

            // Double tap detection
            if (now - lastTap < 300) {
                e.preventDefault();
                e.stopPropagation();

                const deltaX = Math.abs(x - lastTapX);
                if (deltaX < 50) {
                    // Double tap center = fullscreen
                    props.onToggleFullscreen();
                } else if (x < width / 2) {
                    // Double tap left = seek -10s
                    props.onSeek(-10);
                } else {
                    // Double tap right = seek +10s
                    props.onSeek(10);
                }
                lastTap = 0;
                return;
            }

            lastTap = now;
            lastTapX = x;

            // Single tap after delay
            setTimeout(() => {
                if (lastTap === now) {
                    // Check if touch device
                    const isTouch = window.matchMedia('(pointer: coarse)').matches;
                    if (isTouch) {
                        props.onToggleControls();
                    } else {
                        props.onTogglePlay();
                    }
                }
            }, 300);
        }

        return () => (
            <div
                class="absolute inset-0 z-10"
                onPointerup={handlePointerUp}
                style={{ touchAction: 'none' }}
            />
        );
    }
});
