import { defineComponent, PropType, computed, ref } from 'vue';
import CIcon from '../c-icon.vue';

interface VariantTrack {
    id: number;
    width: number;
    height: number;
    bandwidth: number;
    active: boolean;
    videoMimeType?: string;
    videoCodec?: string;
}

export default defineComponent({
    name: 'PlayerQualityMenu',
    props: {
        variantTracks: {
            type: Array as PropType<VariantTrack[]>,
            default: () => []
        },
        isAutoQuality: {
            type: Boolean,
            default: true
        },
        activeQuality: {
            type: Object as PropType<{ width: number; height: number; bandwidth: number } | null>,
            default: null
        },
        onSelectQuality: {
            type: Function as PropType<(bandwidth: number) => void>,
            required: true
        },
        onEnableAuto: {
            type: Function as PropType<() => void>,
            required: true
        }
    },
    setup(props) {
        const isOpen = ref(false);

        const formatBitrate = (bps: number): string => {
            if (bps >= 1_000_000) return `${(bps / 1_000_000).toFixed(1)} Mbps`;
            if (bps >= 1_000) return `${(bps / 1_000).toFixed(0)} Kbps`;
            return `${bps} bps`;
        };

        const formatGbPerHour = (bps: number): string => {
            const gb = (bps * 3600) / (8 * 1024 * 1024 * 1024);
            if (gb < 0.01) return '<0.01 GB/h';
            return `${gb.toFixed(2)} GB/h`;
        };

        // Deduplicate by bandwidth, keep one track per unique bitrate
        const uniqueQualities = computed(() => {
            const seen = new Map<number, VariantTrack>();
            for (const track of props.variantTracks) {
                if (!seen.has(track.bandwidth)) {
                    seen.set(track.bandwidth, track);
                }
            }
            return Array.from(seen.values()).sort((a, b) => b.bandwidth - a.bandwidth);
        });

        const hasMultipleQualities = computed(() => uniqueQualities.value.length > 1);

        const toggleMenu = () => {
            if (hasMultipleQualities.value) {
                isOpen.value = !isOpen.value;
            }
        };

        const handleClickOutside = () => {
            isOpen.value = false;
        };

        const handleSelectAuto = () => {
            props.onEnableAuto();
            isOpen.value = false;
        };

        const handleSelectQuality = (track: VariantTrack) => {
            props.onSelectQuality(track.bandwidth);
            isOpen.value = false;
        };

        return () => (
            <div class="relative">
                {/* Quality button */}
                <button
                    onClick={toggleMenu}
                    class={`player-control-btn ${!hasMultipleQualities.value ? 'opacity-40 cursor-default' : ''}`}
                    aria-label="Quality settings"
                >
                    <CIcon icon="settings" size={18} />
                </button>

                {/* Dropdown menu */}
                {isOpen.value && hasMultipleQualities.value && (
                    <>
                        {/* Backdrop */}
                        <div
                            class="fixed inset-0 z-40"
                            onClick={handleClickOutside}
                        />

                        {/* Menu panel */}
                        <div class="absolute right-0 top-full mt-2 z-50 min-w-[240px] rounded-xl border border-white/[0.08] bg-black/80 backdrop-blur-2xl shadow-2xl shadow-black/50 overflow-hidden">
                            {/* Header */}
                            <div class="px-3.5 pt-3 pb-2">
                                <span class="text-[0.65rem] font-semibold uppercase tracking-wider text-white/40">
                                    Calidad de video
                                </span>
                            </div>

                            {/* Track list */}
                            <div class="px-1.5 pb-1.5">
                                {/* Auto option */}
                                <button
                                    onClick={handleSelectAuto}
                                    class={[
                                        'flex items-center gap-3 w-full px-3 py-2 rounded-lg text-left transition-all duration-150 ease-out cursor-pointer outline-none',
                                        props.isAutoQuality
                                            ? 'bg-white/[0.10] text-white'
                                            : 'text-white/70 hover:bg-white/[0.06] hover:text-white'
                                    ]}
                                >
                                    {/* Check indicator */}
                                    <div class={[
                                        'w-4 h-4 rounded-full flex items-center justify-center flex-shrink-0 transition-colors',
                                        props.isAutoQuality
                                            ? 'bg-[var(--c-player-accent-color,#38bdf8)]'
                                            : 'border border-white/20'
                                    ]}>
                                        {props.isAutoQuality && (
                                            <svg class="w-2.5 h-2.5 text-black" viewBox="0 0 12 12" fill="none">
                                                <path d="M2 6l3 3 5-5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                                            </svg>
                                        )}
                                    </div>

                                    <div class="flex flex-col min-w-0 flex-1">
                                        <span class="text-sm font-medium">Automática</span>
                                        <span class="text-[0.65rem] text-white/40 mt-0.5">
                                            Ajusta según conexión
                                        </span>
                                    </div>

                                    {props.isAutoQuality && props.activeQuality && (
                                        <span class="text-[0.65rem] tabular-nums text-white/50">
                                            {formatBitrate(props.activeQuality.bandwidth)}
                                        </span>
                                    )}
                                </button>

                                {/* Divider */}
                                <div class="h-px bg-white/[0.06] mx-2 my-1" />

                                {/* Quality options */}
                                {uniqueQualities.value.map((track) => {
                                    const isActive = !props.isAutoQuality && track.bandwidth === props.activeQuality?.bandwidth;
                                    return (
                                        <button
                                            key={track.id}
                                            onClick={() => handleSelectQuality(track)}
                                            class={[
                                                'flex items-center gap-3 w-full px-3 py-2 rounded-lg text-left transition-all duration-150 ease-out cursor-pointer outline-none',
                                                isActive
                                                    ? 'bg-white/[0.10] text-white'
                                                    : 'text-white/70 hover:bg-white/[0.06] hover:text-white'
                                            ]}
                                        >
                                            {/* Check indicator */}
                                            <div class={[
                                                'w-4 h-4 rounded-full flex items-center justify-center flex-shrink-0 transition-colors',
                                                isActive
                                                    ? 'bg-[var(--c-player-accent-color,#38bdf8)]'
                                                    : 'border border-white/20'
                                            ]}>
                                                {isActive && (
                                                    <svg class="w-2.5 h-2.5 text-black" viewBox="0 0 12 12" fill="none">
                                                        <path d="M2 6l3 3 5-5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                                                    </svg>
                                                )}
                                            </div>

                                            <div class="flex flex-col min-w-0 flex-1">
                                                <span class="text-sm font-medium">
                                                    {formatBitrate(track.bandwidth)}
                                                </span>
                                                <span class="text-[0.65rem] text-white/40 mt-0.5">
                                                    ~{formatGbPerHour(track.bandwidth)}
                                                </span>
                                            </div>

                                            {isActive && (
                                                <CIcon icon="check" size={14} class="text-white/50" />
                                            )}
                                        </button>
                                    );
                                })}
                            </div>
                        </div>
                    </>
                )}
            </div>
        );
    }
});
