import { defineComponent, ref, PropType } from "vue";
import CIcon from "../c-icon.vue";
import PluginOutlet from "../PluginOutlet";
import PlayerAudioMenu from "./PlayerAudioMenu";
import PlayerQualityMenu from "./PlayerQualityMenu";
import PlayerSegmentAdmin from "./PlayerSegmentAdmin";
import type { AudioTrackInfo } from "@/composables/useMediaPlayerState";

interface VariantTrack {
    id: number;
    width: number;
    height: number;
    bandwidth: number;
    active: boolean;
}

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
        },
        onCast: {
            type: Function as PropType<() => void>,
            default: null
        },
        isCasting: {
            type: Boolean,
            default: false
        },
        audioTracks: {
            type: Array as PropType<AudioTrackInfo[]>,
            default: () => []
        },
        onSelectAudioTrack: {
            type: Function as PropType<(language: string, role?: string) => void>,
            default: null
        },
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
            default: null
        },
        onEnableAutoQuality: {
            type: Function as PropType<() => void>,
            default: null
        },
        contentId: {
            type: String,
            default: null
        },
        episodeId: {
            type: String,
            default: null
        },
        currentTime: {
            type: Number,
            default: 0
        },
        isAdmin: {
            type: Boolean,
            default: false
        }
    },
    setup(props) {
        const { episode, season } = props.content;
        const seasonTitle = season?.title || null;
        const episodeTitle = episode?.title || null;

        return () => (
            <div class="pointer-events-auto w-full">
                {/* Top gradient + glass panel */}
                <div class="flex w-full items-center px-5 py-3 bg-gradient-to-b from-black/70 via-black/40 to-transparent">
                    <div class="mx-auto flex w-full max-w-7xl items-center justify-between">
                        {/* Left: back + title */}
                        <div class="flex items-center gap-3 min-w-0">
                            <button
                                onClick={() => props.backToContent()}
                                class="player-control-btn flex-shrink-0"
                                aria-label="Volver"
                            >
                                <CIcon icon="arrow-left" size={18} />
                            </button>
                            <div class="flex flex-col min-w-0">
                                <span class="text-white text-base font-semibold truncate max-w-[40vw]">
                                    {props.content?.content?.title || ''}
                                </span>
                                {episodeTitle && seasonTitle && (
                                    <span class="text-white/50 text-xs font-medium truncate max-w-[35vw]">
                                        {seasonTitle} · {episodeTitle}
                                    </span>
                                )}
                            </div>
                        </div>

                        {/* Right: controls */}
                        <div class="flex items-center gap-1.5">
                            {/* Segment admin (admin only) */}
                            {props.isAdmin && props.contentId && (
                                <PlayerSegmentAdmin
                                    contentId={props.contentId}
                                    episodeId={props.episodeId}
                                    currentTime={props.currentTime}
                                />
                            )}

                            {/* Audio tracks */}
                            {props.audioTracks.length > 0 && props.onSelectAudioTrack && (
                                <PlayerAudioMenu
                                    audioTracks={props.audioTracks}
                                    onSelectTrack={props.onSelectAudioTrack}
                                />
                            )}

                            {/* Quality settings */}
                            {props.variantTracks.length > 0 && props.onSelectQuality && props.onEnableAutoQuality && (
                                <PlayerQualityMenu
                                    variantTracks={props.variantTracks}
                                    isAutoQuality={props.isAutoQuality}
                                    activeQuality={props.activeQuality}
                                    onSelectQuality={props.onSelectQuality}
                                    onEnableAuto={props.onEnableAutoQuality}
                                />
                            )}

                            {/* Cast */}
                            {props.googleCastEnabled && props.onCast && (
                                <button
                                    onClick={props.onCast}
                                    title="Cast to device"
                                    class={`player-control-btn ${props.isCasting ? 'text-[var(--c-player-accent-color,#00A8E1)]' : ''}`}
                                >
                                    <CIcon icon="airplay" size={18} />
                                </button>
                            )}

                            <PluginOutlet name="player:top-controls:right" />

                            {/* Divider */}
                            <div class="w-px h-5 bg-white/[0.12] mx-1" />

                            {/* Close */}
                            <button
                                onClick={() => props.backToContent()}
                                class="player-control-btn"
                                aria-label="Close player"
                            >
                                <CIcon icon="x" size={18} />
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        );
    }
});
