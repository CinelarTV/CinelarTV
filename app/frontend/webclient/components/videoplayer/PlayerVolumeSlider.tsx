import { MediaPlayer } from "vidstack";
import { computed, defineComponent, defineProps, onMounted, ref } from "vue";
import CIcon from "../c-icon.vue";
import { MediaVolumeSliderElement } from "vidstack/elements";

export default defineComponent({
    name: 'PlayerVolumeSlider',
    props: {
        playerElement: {
            type: Object as () => MediaPlayer,
            required: true
        }
    },
    setup(props) {

        const currentVolume = ref(props.playerElement?.volume);
        const isMuted = ref(props.playerElement?.muted);

        const ICONS = {
            muted: "volume-x",
            low: "volume1",
            high: "volume2"
        }

        const COMPUTED_VOLUME_ICON = computed(() => {
            if (isMuted.value || currentVolume.value === 0) return ICONS.muted;
            if (currentVolume.value > 0 && currentVolume.value < 0.7) return ICONS.low;
            return ICONS.high;
        });

        onMounted(() => {


            const instance = document.querySelector("media-volume-slider") as MediaVolumeSliderElement
            instance.subscribe(({ value }) => {
                currentVolume.value = value / 100;
                isMuted.value = props.playerElement?.muted;
            })


        })


        return () => (
            <div class="flex items-center space-x-2 w-[200px]">
                <CIcon icon={COMPUTED_VOLUME_ICON.value} />
                <media-volume-slider
                    class="group relative mx-[7.5px] inline-flex h-10 w-full max-w-[80px] cursor-pointer touch-none select-none items-center outline-none aria-hidden:hidden"
                >
                    <div
                        class="relative z-0 h-[5px] w-full rounded-sm bg-white/30 ring-sky-400 group-data-[focus]:ring-[3px]"
                    >
                        <div
                            class="absolute h-full w-[var(--slider-fill)] rounded-sm bg-indigo-400 will-change-[width]"
                        ></div>
                    </div>
                    <div
                        class="absolute left-[var(--slider-fill)] top-1/2 z-20 h-[15px] w-[15px] -translate-x-1/2 -translate-y-1/2 rounded-full border border-[#cacaca] bg-white opacity-0 ring-white/40 transition-opacity will-change-[left] group-data-[active]:opacity-100 group-data-[dragging]:ring-4"
                    ></div>
                </media-volume-slider>
            </div>
        )
    }
});