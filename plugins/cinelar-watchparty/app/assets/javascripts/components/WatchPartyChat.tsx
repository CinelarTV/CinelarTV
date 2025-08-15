import "../../styles/watchparty.css"
import { defineComponent, ref, onMounted, onBeforeUnmount } from "vue";

export default defineComponent({
    name: "WatchPartyChat",
    setup() {
        const visible = ref(false);
        const toggle = () => (visible.value = !visible.value);

        // Sincroniza con el evento personalizado
        const handleToggle = (e: Event) => {
            const customEvent = e as CustomEvent;
            if (customEvent.detail && typeof customEvent.detail.opened === 'boolean') {
                visible.value = customEvent.detail.opened;
            }
        };

        onMounted(() => {
            window.addEventListener('watchparty-toggle', handleToggle);
        });
        onBeforeUnmount(() => {
            window.removeEventListener('watchparty-toggle', handleToggle);
        });

        return () => (
            <div
                class={['watchparty-chat', visible.value && 'opened'].filter(Boolean).join(' ')}
                style={{ zIndex: 999 }}
            >
                <div class="watchparty-chat-inner">
                    <div class="flex flex-col bg-black shadow-2xl h-full w-full border-l border-gray-200">
                        <div class="flex items-center justify-between p-4 border-b border-gray-200">
                            <h3 class="font-bold mb-0">Watch Party Chat</h3>
                        </div>
                        <div class="chat-content p-4 flex-1 overflow-y-auto">
                            {/* Aquí iría la implementación del chat */}
                        </div>
                    </div>
                </div>
            </div>
        )
    }
});