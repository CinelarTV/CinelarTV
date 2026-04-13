// @ts-ignore - Side-effect CSS import handled by bundler
import "../../styles/watchparty.css";
import { defineComponent, ref, onMounted, onBeforeUnmount, nextTick, getCurrentInstance, watch } from "vue";
import { useWatchParty } from "../services/watchparty-service";

export default defineComponent({
    name: "WatchPartyChat",
    setup() {
        const { state, sendMessage, userCount, isConnected, addSystemMessage, autoJoinFromUrl } = useWatchParty();
        const visible = ref(false);
        const messageInput = ref("");
        const messagesContainer = ref<HTMLElement | null>(null);
        const { $t } = getCurrentInstance()!.appContext.config.globalProperties;

        // Auto-join from URL on mount
        onMounted(async () => {
            await autoJoinFromUrl();
        });

        const scrollToBottom = async () => {
            await nextTick();
            if (messagesContainer.value) {
                messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight;
            }
        };

        const handleSendMessage = () => {
            if (!messageInput.value.trim()) return;
            sendMessage(messageInput.value);
            messageInput.value = "";
            scrollToBottom();
        };

        const handleToggle = (e: Event) => {
            const customEvent = e as CustomEvent;
            if (customEvent.detail && typeof customEvent.detail.opened === 'boolean') {
                visible.value = customEvent.detail.opened;
                scrollToBottom();
            }
        };

        const handleChatToggle = () => {
            visible.value = !visible.value;
            scrollToBottom();
        };

        const setChatOpenState = (opened: boolean) => {
            document.body.classList.toggle('watchparty-chat-open', opened);
            window.dispatchEvent(new CustomEvent('watchparty-chat-state', { detail: { opened } }));
        };

        watch(visible, (opened) => {
            setChatOpenState(opened);
        });

        onMounted(() => {
            window.addEventListener('watchparty-toggle', handleToggle);
            window.addEventListener('watchparty-chat-toggle', handleChatToggle);
        });

        onBeforeUnmount(() => {
            window.removeEventListener('watchparty-toggle', handleToggle);
            window.removeEventListener('watchparty-chat-toggle', handleChatToggle);
            setChatOpenState(false);
        });

        const formatTime = (date: Date) => {
            return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
        };

        return () => (
            <div
                class={[
                    "watchparty-chat-panel",
                    visible.value && "watchparty-chat-panel--open"
                ]}
            >
                {/* Chat Header */}
                <div class="watchparty-chat-panel__header">
                    <div class="flex items-center justify-between px-4 py-3">
                        <div class="flex items-center gap-2">
                            <div class="w-2 h-2 rounded-full bg-green-500 animate-pulse" />
                            <h3 class="text-sm font-semibold text-white">
                                WatchParty
                            </h3>
                            {isConnected.value && (
                                <span class="text-xs text-white/60">
                                    ({userCount.value})
                                </span>
                            )}
                        </div>
                        <button
                            onClick={() => visible.value = false}
                            class="p-1.5 rounded-lg hover:bg-white/10 transition-colors"
                        >
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="w-4 h-4 text-white/60 hover:text-white">
                                <line x1="18" y1="6" x2="6" y2="18" />
                                <line x1="6" y1="6" x2="18" y2="18" />
                            </svg>
                        </button>
                    </div>
                </div>

                {/* Messages */}
                <div ref={messagesContainer} class="watchparty-chat-panel__messages">
                    {state.value.messages.length === 0 ? (
                        <div class="flex flex-col items-center justify-center h-full text-center p-6">
                            <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" class="w-12 h-12 text-white/20 mb-3">
                                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
                            </svg>
                            <p class="text-sm text-white/40">
                                No hay mensajes aún
                            </p>
                            <p class="text-xs text-white/30 mt-1">
                                ¡Sé el primero en decir algo!
                            </p>
                        </div>
                    ) : (
                        <div class="space-y-3 p-4">
                            {state.value.messages.map((message) => (
                                <div
                                    key={message.id}
                                    class={[
                                        "flex gap-2",
                                        message.type === 'system' ? 'justify-center' : ''
                                    ]}
                                >
                                    {message.type === 'system' ? (
                                        <div class="text-xs text-white/40 italic">
                                            {message.text}
                                        </div>
                                    ) : message.type === 'playback' ? (
                                        <div class="flex items-center gap-1 text-xs text-white/50">
                                            <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="currentColor" class="w-3 h-3">
                                                <polygon points="5 3 19 12 5 21 5 3" />
                                            </svg>
                                            {message.text}
                                        </div>
                                    ) : (
                                        <div class="flex gap-2 max-w-[85%]">
                                            <div class="flex-shrink-0 w-7 h-7 rounded-full bg-[#00A8E1]/30 flex items-center justify-center text-xs font-semibold text-[#00A8E1]">
                                                {message.user.name.charAt(0).toUpperCase()}
                                            </div>
                                            <div>
                                                <div class="flex items-center gap-2 mb-0.5">
                                                    <span class="text-xs font-medium text-white/80">
                                                        {message.user.name}
                                                    </span>
                                                    <span class="text-[10px] text-white/30">
                                                        {formatTime(message.timestamp)}
                                                    </span>
                                                </div>
                                                <div class="text-sm text-white/90 bg-white/10 rounded-lg px-3 py-1.5">
                                                    {message.text}
                                                </div>
                                            </div>
                                        </div>
                                    )}
                                </div>
                            ))}
                        </div>
                    )}
                </div>

                {/* Input */}
                {isConnected.value && (
                    <div class="watchparty-chat-panel__input">
                        <form
                            onSubmit={(e) => {
                                e.preventDefault();
                                handleSendMessage();
                            }}
                            class="flex items-center gap-2 p-3"
                        >
                            <input
                                type="text"
                                value={messageInput.value}
                                onInput={(e) => {
                                    messageInput.value = (e.target as HTMLInputElement).value;
                                }}
                                placeholder="Escribe un mensaje..."
                                class="flex-1 px-3 py-2 bg-white/10 border border-white/10 rounded-lg text-sm text-white placeholder-white/40 focus:outline-none focus:ring-2 focus:ring-[#00A8E1]/50 focus:border-transparent"
                            />
                            <button
                                type="submit"
                                disabled={!messageInput.value.trim()}
                                class="p-2 rounded-lg bg-[#00A8E1] hover:bg-[#0097C9] text-white disabled:opacity-50 disabled:cursor-not-allowed transition-all duration-200 hover:scale-105"
                            >
                                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="w-5 h-5">
                                    <line x1="22" y1="2" x2="11" y2="13" />
                                    <polygon points="22 2 15 22 11 13 2 9 22 2" />
                                </svg>
                            </button>
                        </form>
                    </div>
                )}
            </div>
        );
    }
});
