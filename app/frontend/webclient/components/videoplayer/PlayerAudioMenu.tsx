import { defineComponent, PropType, computed, ref } from 'vue';
import CIcon from '../c-icon.vue';
import type { AudioTrackInfo } from '@/composables/useMediaPlayerState';

export default defineComponent({
    name: 'PlayerAudioMenu',
    props: {
        audioTracks: {
            type: Array as PropType<AudioTrackInfo[]>,
            default: () => []
        },
        onSelectTrack: {
            type: Function as PropType<(language: string, role?: string) => void>,
            required: true
        }
    },
    setup(props) {
        const isOpen = ref(false);

        const hasMultipleTracks = computed(() => props.audioTracks.length > 1);

        const activeTrack = computed(() => props.audioTracks.find(t => t.active));

        const formatLabel = (track: AudioTrackInfo): string => {
            if (track.label) return track.label;

            const lang = track.language === 'und' ? 'Desconocido' : track.language.toUpperCase();
            if (track.roles.length > 0 && !track.roles.includes('main')) {
                const roleLabel = track.roles[0] === 'audio_description'
                    ? 'Audio descriptivo'
                    : track.roles[0];
                return `${lang} (${roleLabel})`;
            }
            return lang;
        };

        const formatChannels = (channels: number | null): string => {
            if (!channels) return '';
            if (channels === 1) return 'Mono';
            if (channels === 2) return 'Stereo';
            if (channels === 6) return '5.1';
            if (channels === 8) return '7.1';
            return `${channels}ch`;
        };

        const handleSelect = (track: AudioTrackInfo) => {
            props.onSelectTrack(track.language, track.roles[0]);
            isOpen.value = false;
        };

        const toggleMenu = () => {
            if (hasMultipleTracks.value) {
                isOpen.value = !isOpen.value;
            }
        };

        const handleClickOutside = () => {
            isOpen.value = false;
        };

        return () => (
            <div class="relative">
                {/* Audio button */}
                <button
                    onClick={toggleMenu}
                    class={`player-control-btn ${!hasMultipleTracks.value ? 'opacity-40 cursor-default' : ''}`}
                    aria-label="Audio tracks"
                    title={activeTrack.value ? formatLabel(activeTrack.value) : 'Audio'}
                >
                    <CIcon icon="languages" size={18} />
                </button>

                {/* Dropdown menu */}
                {isOpen.value && hasMultipleTracks.value && (
                    <>
                        {/* Backdrop */}
                        <div
                            class="fixed inset-0 z-40"
                            onClick={handleClickOutside}
                        />

                        {/* Menu panel */}
                        <div class="absolute right-0 top-full mt-2 z-50 min-w-[220px] rounded-xl border border-white/[0.08] bg-black/80 backdrop-blur-2xl shadow-2xl shadow-black/50 overflow-hidden">
                            {/* Header */}
                            <div class="px-3.5 pt-3 pb-2">
                                <span class="text-[0.65rem] font-semibold uppercase tracking-wider text-white/40">
                                    Idioma de audio
                                </span>
                            </div>

                            {/* Track list */}
                            <div class="px-1.5 pb-1.5">
                                {props.audioTracks.map((track) => (
                                    <button
                                        key={`${track.language}-${track.roles.join('-')}`}
                                        onClick={() => handleSelect(track)}
                                        class={[
                                            'flex items-center gap-3 w-full px-3 py-2 rounded-lg text-left transition-all duration-150 ease-out cursor-pointer outline-none',
                                            track.active
                                                ? 'bg-white/[0.10] text-white'
                                                : 'text-white/70 hover:bg-white/[0.06] hover:text-white'
                                        ]}
                                    >
                                        {/* Check indicator */}
                                        <div class={[
                                            'w-4 h-4 rounded-full flex items-center justify-center flex-shrink-0 transition-colors',
                                            track.active
                                                ? 'bg-[var(--c-player-accent-color,#38bdf8)]'
                                                : 'border border-white/20'
                                        ]}>
                                            {track.active && (
                                                <svg class="w-2.5 h-2.5 text-black" viewBox="0 0 12 12" fill="none">
                                                    <path d="M2 6l3 3 5-5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                                                </svg>
                                            )}
                                        </div>

                                        {/* Label + meta */}
                                        <div class="flex flex-col min-w-0 flex-1">
                                            <span class="text-sm font-medium truncate">
                                                {formatLabel(track)}
                                            </span>
                                            {track.channelsCount && (
                                                <span class="text-[0.65rem] text-white/40 mt-0.5">
                                                    {formatChannels(track.channelsCount)}
                                                </span>
                                            )}
                                        </div>
                                    </button>
                                ))}
                            </div>
                        </div>
                    </>
                )}
            </div>
        );
    }
});
