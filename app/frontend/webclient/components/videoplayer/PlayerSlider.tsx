import { defineComponent } from "vue";

export default defineComponent({
    name: 'PlayerSlider',
    setup() {
        return () => (
            <media-time-slider
                class="group relative inline-flex h-10 w-full cursor-pointer touch-none select-none items-center outline-none aria-hidden:hidden"
            >
                <div
                    class="relative z-0 h-[5px] w-full rounded-sm bg-white/30 ring-sky-400 group-data-[focus]:ring-[3px]"
                >
                    <div
                        class="absolute h-full w-[var(--slider-fill)] rounded-sm bg-indigo-400 will-change-[width]"
                    ></div>
                    <div
                        class="absolute z-10 h-full w-[var(--slider-progress)] rounded-sm bg-black/40 will-change-[width]"
                    ></div>
                </div>
                <div
                    class="absolute left-[var(--slider-fill)] top-1/2 z-20 h-[15px] w-[15px] -translate-x-1/2 -translate-y-1/2 rounded-full border border-[#cacaca] bg-white opacity-0 ring-white/40 transition-opacity will-change-[left] group-data-[active]:opacity-100 group-data-[dragging]:ring-4"
                ></div>
            </media-time-slider>
        )
    }
});