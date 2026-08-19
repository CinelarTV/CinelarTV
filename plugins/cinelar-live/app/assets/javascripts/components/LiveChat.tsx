import { defineComponent, ref, onMounted, onUnmounted, nextTick, watch, computed } from "vue";
import { useLiveChat, ChatMessage } from "../services/live-chat-service";
import { useCurrentUser } from "@/app/services/current-user";
import CButton from "@/components/forms/c-button";

export default defineComponent({
  name: "LiveChat",
  props: {
    eventId: { type: Number, required: true },
    isOrganizer: { type: Boolean, default: false },
  },
  setup(props) {
    const {
      messages,
      loadMessages,
      sendMessage,
      deleteMessage,
      subscribeToChat,
      unsubscribeFromChat,
    } = useLiveChat();

    const currentUser = useCurrentUser();
    const inputText = ref("");
    const messagesContainer = ref<HTMLDivElement | null>(null);
    const isAtBottom = ref(true);

    const canDeleteMessage = (msg: ChatMessage) => {
      if (props.isOrganizer) return true;
      return currentUser?.id === msg.profile_id;
    };

    const handleSend = () => {
      if (!inputText.value.trim()) return;
      sendMessage(props.eventId, inputText.value);
      inputText.value = "";
    };

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        handleSend();
      }
    };

    const handleDelete = (msg: ChatMessage) => {
      deleteMessage(props.eventId, msg.id);
    };

    const scrollToBottom = () => {
      if (messagesContainer.value && isAtBottom.value) {
        messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight;
      }
    };

    const handleScroll = () => {
      if (!messagesContainer.value) return;
      const { scrollTop, scrollHeight, clientHeight } = messagesContainer.value;
      isAtBottom.value = scrollHeight - scrollTop - clientHeight < 50;
    };

    watch(messages, () => {
      nextTick(scrollToBottom);
    }, { deep: true });

    onMounted(async () => {
      await loadMessages(props.eventId);
      subscribeToChat(props.eventId);
      nextTick(scrollToBottom);
    });

    onUnmounted(() => {
      unsubscribeFromChat(props.eventId);
    });

    const formatTime = (timestamp: string) => {
      const d = new Date(timestamp);
      return d.toLocaleTimeString("es-ES", { hour: "2-digit", minute: "2-digit" });
    };

    return () => (
      <div class="c-live-chat">
        <div class="c-live-chat__header">
          <h3 class="c-live-chat__title">Chat en vivo</h3>
          <span class="c-live-chat__count">{messages.value.length} mensajes</span>
        </div>

        <div
          ref={messagesContainer}
          class="c-live-chat__messages"
          onScroll={handleScroll}
        >
          {messages.value.length === 0 && (
            <div class="c-live-chat__empty">
              <p>No hay mensajes aún</p>
            </div>
          )}

          {messages.value.map((msg) => (
            <div key={msg.id} class={`c-live-chat__message ${msg.message_type === "system" ? "c-live-chat__message--system" : ""}`}>
              {msg.message_type === "system" ? (
                <span class="c-live-chat__message-system">{msg.body}</span>
              ) : msg.deleted ? (
                <div class="c-live-chat__message-deleted">
                  <div class="c-live-chat__avatar c-live-chat__avatar--placeholder">?</div>
                  <span>Mensaje eliminado</span>
                </div>
              ) : (
                <div class="c-live-chat__message-row">
                  <img
                    src={msg.avatar}
                    alt=""
                    class="c-live-chat__avatar"
                  />
                  <div class="c-live-chat__message-content">
                    <div class="c-live-chat__message-meta">
                      <span class="c-live-chat__username">{msg.username}</span>
                      <span class="c-live-chat__time">{formatTime(msg.timestamp)}</span>
                    </div>
                    <p class="c-live-chat__body">{msg.body}</p>
                  </div>
                  {canDeleteMessage(msg) && (
                    <CButton
                      onClick={() => handleDelete(msg)}
                      class="c-live-chat__delete"
                      title="Eliminar mensaje"
                    >
                      <svg class="c-live-chat__delete-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                      </svg>
                    </CButton>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>

        <div class="c-live-chat__footer">
          <div class="c-live-chat__input-row">
            <input
              type="text"
              value={inputText.value}
              onInput={(e: InputEvent) => { inputText.value = (e.target as HTMLInputElement).value; }}
              onKeyDown={handleKeyDown}
              placeholder="Escribe un mensaje..."
              maxlength={500}
              class="c-live-chat__input"
            />
            <CButton
              onClick={handleSend}
              disabled={!inputText.value.trim()}
              class="c-live-chat__send"
            >
              Enviar
            </CButton>
          </div>
        </div>
      </div>
    );
  },
});
