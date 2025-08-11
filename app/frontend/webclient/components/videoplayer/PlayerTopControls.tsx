import { defineComponent } from "vue";
import CIcon from "../c-icon.vue";

export default defineComponent({
    name: "PlayerTopControls",
    props: {
        googleCastEnabled: {
            type: Boolean,
            default: false
        },
        content: {
            type: Object,
            required: true
        },
        backToContent: {
            type: Function,
            required: true
        }
    },
    setup(props) {
        const { googleCastEnabled, backToContent } = props;

        const { episode, season } = props.content;

        const seasonTitle = season?.title || "Temporada desconocida";
        const episodeTitle = episode?.title || "Episodio desconocido";

        return () => (
            <media-controls-group class="pointer-events-auto h-20 flex w-full items-center px-4 bg-gradient-to-b from-black/50 to-transparent">
                <div class="max-w-7xl mx-auto w-full flex items-center py-4 justify-between">
                    <div class="flex flex-col">
                        <media-title class="text-white text-2xl font-semibold" />
                        {episodeTitle && seasonTitle && (
                            <div class="text-white text-sm">
                                {seasonTitle} - {episodeTitle}
                            </div>
                        )}
                    </div>

                    <div class="flex items-center gap-2">
                        <media-menu>
                            <media-menu-button
                                class="group relative flex size-10 cursor-pointer items-center justify-center rounded-md outline-none ring-inset ring-sky-400 hover:bg-white/20 data-[focus]:ring-4"
                                aria-label="Settings"
                            >
                                <CIcon icon="settings" class="transform transition-transform duration-200 ease-out group-data-[open]:rotate-90" />
                            </media-menu-button>
                            <media-menu-items
                                class="flex h-[var(--menu-height)] max-h-[400px] min-w-[260px] flex-col overflow-y-auto overscroll-y-contain rounded-md border border-white/10 bg-black/95 p-2.5 font-sans text-[15px] font-medium outline-none backdrop-blur-sm transition-[height] duration-300 will-change-[height] animate-out fade-out slide-out-to-bottom-2 data-[resizing]:overflow-hidden data-[open]:animate-in data-[open]:fade-in data-[open]:slide-in-from-bottom-4"
                                placement="top"
                                offset="0"
                            >
                            </media-menu-items>
                        </media-menu>

                        <media-fullscreen-button
                            class="group relative inline-flex h-10 w-10 cursor-pointer items-center justify-center rounded-md outline-none ring-inset ring-sky-400 hover:bg-white/20 aria-hidden:hidden data-[focus]:ring-4"
                        >
                            <CIcon icon="maximize" class=" group-data-[active]:hidden" />
                            <CIcon icon="shrink" class="hidden group-data-[active]:block" />
                        </media-fullscreen-button>

                        {
                            googleCastEnabled && (
                                <media-tooltip class="contents">
                                    <media-tooltip-trigger>
                                        <media-google-cast-button
                                            class="group relative inline-flex h-10 w-10 cursor-pointer items-center justify-center rounded-md outline-none ring-inset ring-sky-400 hover:bg-white/20 data-[focus]:ring-4"
                                        >
                                            <CIcon icon="airplay" />
                                        </media-google-cast-button>
                                    </media-tooltip-trigger>
                                    <media-tooltip-content
                                        class="z-10 rounded-sm border border-gray-400/20 bg-black/90 px-2 py-0.5 text-sm font-medium text-white animate-fade-out animate-duration-200 data-[visible]:animate-fade-in data-[visible]:animate-duration-100"
                                        placement="top start"
                                    >
                                        Cast to device
                                    </media-tooltip-content>
                                </media-tooltip>

                            )
                        }




                        <hr class="h-6 border-l border-white/10" />
                        <button
                            onClick={() => backToContent()}
                            class="group relative flex size-10 cursor-pointer items-center justify-center rounded-md outline-none ring-inset ring-sky-400 hover:bg-white/20 data-[focus]:ring-4">
                            <CIcon icon="x" />
                        </button>
                    </div>
                </div>

            </media-controls-group>
        )
    }
});
