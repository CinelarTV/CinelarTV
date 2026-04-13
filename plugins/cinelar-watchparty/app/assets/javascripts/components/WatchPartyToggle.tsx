import { defineComponent, ref, computed, getCurrentInstance, inject, onMounted } from "vue";
import { useWatchParty } from "../services/watchparty-service";

export default defineComponent({
    name: "WatchPartyToggle",
    setup() {
        // Try to get contentId from player context first, fallback to route
        const playerContentId = inject<string | null>('playerContentId', null);
        const playerEpisodeId = inject<string | null>('playerEpisodeId', null);

        const { state, createSession, leaveSession, userCount, isConnected, getShareUrl, autoJoinFromUrl } = useWatchParty();
        const isPanelOpen = ref(false);
        const copySuccess = ref(false);
        const { $t } = getCurrentInstance()!.appContext.config.globalProperties;

        // Content ID: prefer from player context, fallback to route
        const contentId = computed(() => {
            return playerContentId;
        });

        const episodeId = computed(() => {
            return playerEpisodeId;
        });

        // Auto-join from URL on mount
        onMounted(async () => {
            await autoJoinFromUrl();
        });

        const handleToggle = () => {
            isPanelOpen.value = !isPanelOpen.value;
        };

        const handleCreateSession = async () => {
            if (!contentId.value) {
                console.error('No content ID available for WatchParty session');
                return;
            }
            try {
                await createSession(contentId.value);
                isPanelOpen.value = true;
            } catch (error) {
                console.error('Failed to create session:', error);
            }
        };

        const handleLeaveSession = async () => {
            await leaveSession();
            isPanelOpen.value = false;
        };

        const handleCopyLink = async () => {
            const shareUrl = getShareUrl();
            if (!shareUrl) return;
            try {
                await navigator.clipboard.writeText(shareUrl);
                copySuccess.value = true;
                setTimeout(() => { copySuccess.value = false; }, 2000);
            } catch (err) {
                // Fallback for older browsers
                const textarea = document.createElement('textarea');
                textarea.value = shareUrl;
                document.body.appendChild(textarea);
                textarea.select();
                document.execCommand('copy');
                document.body.removeChild(textarea);
                copySuccess.value = true;
                setTimeout(() => { copySuccess.value = false; }, 2000);
            }
        };

        return () => (
            <div class="relative">
                {/* Toggle Button */}
                <button
                    onClick={handleToggle}
                    class={[
                        "flex items-center gap-2 px-3 py-2 rounded-lg transition-all duration-200 hover:scale-105",
                        isConnected.value
                            ? "bg-[#00A8E1]/20 text-[#00A8E1] hover:bg-[#00A8E1]/30"
                            : "bg-white/10 text-white/80 hover:bg-white/20"
                    ]}
                >
                    <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="w-4 h-4">
                        <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                        <circle cx="9" cy="7" r="4" />
                        <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
                        <path d="M16 3.13a4 4 0 0 1 0 7.75" />
                    </svg>
                    <span class="text-sm font-medium hidden sm:inline">
                        {isConnected.value ? 'WatchParty' : 'Iniciar WatchParty'}
                    </span>
                    {isConnected.value && userCount.value > 0 && (
                        <span class="flex items-center justify-center w-5 h-5 text-[10px] font-bold text-white bg-[#00A8E1] rounded-full">
                            {userCount.value}
                        </span>
                    )}
                </button>

                {/* Dropdown Panel */}
                {isPanelOpen.value && (
                    <div class="absolute right-0 top-full mt-2 w-80 bg-[#1a1a1a] rounded-xl shadow-2xl ring-1 ring-white/10 z-50 overflow-hidden">
                        {!isConnected.value ? (
                            <div class="p-6">
                                <div class="flex items-center gap-3 mb-4">
                                    <div class="w-10 h-10 rounded-lg bg-[#00A8E1]/20 flex items-center justify-center">
                                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="w-5 h-5 text-[#00A8E1]">
                                            <polygon points="5 3 19 12 5 21 5 3" />
                                            <line x1="1" y1="1" x2="23" y2="23" />
                                        </svg>
                                    </div>
                                    <div>
                                        <h3 class="text-base font-semibold text-white">
                                            WatchParty
                                        </h3>
                                        <p class="text-xs text-white/60">
                                            Ve contenido juntos
                                        </p>
                                    </div>
                                </div>

                                <p class="text-sm text-white/80 mb-4">
                                    Crea una sesión y comparte el enlace para ver este contenido sincronizado con otros.
                                </p>

                                <button
                                    onClick={handleCreateSession}
                                    class="w-full px-4 py-2.5 bg-[#00A8E1] hover:bg-[#0097C9] text-white font-semibold rounded-lg transition-all duration-200 hover:scale-105"
                                >
                                    Crear sesión
                                </button>
                            </div>
                        ) : (
                            <div>
                                {/* Header */}
                                <div class="px-4 py-3 border-b border-white/10">
                                    <div class="flex items-center justify-between">
                                        <div class="flex items-center gap-2">
                                            <div class="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                                            <span class="text-sm font-semibold text-white">
                                                En vivo
                                            </span>
                                        </div>
                                        <button
                                            onClick={handleLeaveSession}
                                            class="text-xs text-white/60 hover:text-white transition-colors"
                                        >
                                            Salir
                                        </button>
                                    </div>
                                </div>

                                {/* Share Link */}
                                <div class="px-4 py-3 border-b border-white/10">
                                    <span class="text-xs font-medium text-white/80 block mb-2">
                                        Enlace para compartir
                                    </span>
                                    <div class="flex items-center gap-2">
                                        <input
                                            type="text"
                                            value={getShareUrl()}
                                            readonly
                                            class="flex-1 px-2 py-1.5 text-xs bg-white/5 border border-white/10 rounded text-white/70 truncate focus:outline-none"
                                        />
                                        <button
                                            onClick={handleCopyLink}
                                            class={[
                                                "px-3 py-1.5 text-xs font-medium rounded transition-all flex-shrink-0",
                                                copySuccess.value
                                                    ? "bg-green-500/20 text-green-400"
                                                    : "bg-[#00A8E1]/20 text-[#00A8E1] hover:bg-[#00A8E1]/30"
                                            ]}
                                        >
                                            {copySuccess.value ? '✓ Copiado' : 'Copiar'}
                                        </button>
                                    </div>
                                </div>

                                {/* Participants */}
                                <div class="px-4 py-3 border-b border-white/10">
                                    <div class="flex items-center justify-between mb-2">
                                        <span class="text-xs font-medium text-white/80">
                                            Participantes
                                        </span>
                                        <span class="text-xs text-white/60">
                                            {userCount.value}
                                        </span>
                                    </div>
                                    <div class="flex -space-x-2">
                                        {state.value.users.slice(0, 5).map(user => (
                                            <div
                                                key={user.id}
                                                class="w-8 h-8 rounded-full bg-white/10 border-2 border-[#1a1a1a] flex items-center justify-center text-xs font-semibold text-white"
                                                title={user.name}
                                            >
                                                {user.name.charAt(0).toUpperCase()}
                                            </div>
                                        ))}
                                        {userCount.value > 5 && (
                                            <div class="w-8 h-8 rounded-full bg-white/10 border-2 border-[#1a1a1a] flex items-center justify-center text-[10px] font-semibold text-white/80">
                                                +{userCount.value - 5}
                                            </div>
                                        )}
                                    </div>
                                </div>

                                {/* Quick Actions */}
                                <div class="px-4 py-3">
                                    <button
                                        onClick={() => {
                                            // Open chat panel
                                            window.dispatchEvent(new CustomEvent('watchparty-chat-toggle'));
                                        }}
                                        class="w-full px-3 py-2 text-sm text-white/80 hover:text-white hover:bg-white/10 rounded-lg transition-all flex items-center gap-2"
                                    >
                                        <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="w-4 h-4">
                                            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
                                        </svg>
                                        Abrir chat
                                    </button>
                                </div>
                            </div>
                        )}
                    </div>
                )}
            </div>
        );
    }
});
