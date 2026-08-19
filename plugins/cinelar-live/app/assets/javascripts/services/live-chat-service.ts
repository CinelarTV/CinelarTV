import { ref, nextTick } from "vue";

export interface ChatMessage {
  id: number;
  profile_id: string;
  username: string;
  avatar: string;
  body: string;
  message_type: "user" | "system";
  deleted: boolean;
  timestamp: string;
}

function csrfToken(): string {
  const el = document.querySelector('[name="csrf-token"]') as HTMLMetaElement;
  return el?.content || "";
}

const messages = ref<ChatMessage[]>([]);
const isSubscribed = ref(false);
let messageBusHandler: ((data: any) => void) | null = null;

export function useLiveChat() {
  const loadMessages = async (eventId: number) => {
    try {
      const res = await fetch(`/community/events/${eventId}/chat.json`);
      const data = await res.json();
      messages.value = data.messages || [];
    } catch (e) {
      console.error("[LiveChat] Failed to load messages:", e);
    }
  };

  const sendMessage = async (eventId: number, body: string) => {
    const trimmed = body.trim();
    if (!trimmed) return;

    try {
      await fetch(`/community/events/${eventId}/chat.json`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken(),
        },
        body: JSON.stringify({ body: trimmed }),
      });
    } catch (e) {
      console.error("[LiveChat] Failed to send message:", e);
    }
  };

  const deleteMessage = async (eventId: number, messageId: number) => {
    try {
      await fetch(`/community/events/${eventId}/chat/${messageId}.json`, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": csrfToken(),
        },
      });
    } catch (e) {
      console.error("[LiveChat] Failed to delete message:", e);
    }
  };

  const subscribeToChat = (eventId: number) => {
    if (isSubscribed.value) return;
    if (typeof window === "undefined" || !(window as any).MessageBus) return;

    messageBusHandler = (data: any) => {
      if (data.type === "chat_message") {
        messages.value.push(data as ChatMessage);
      }
      if (data.type === "message_deleted") {
        const msg = messages.value.find((m) => m.id === data.id);
        if (msg) {
          msg.deleted = true;
          msg.body = "";
        }
      }
    };

    (window as any).MessageBus.subscribe(
      `/live/event/${eventId}`,
      messageBusHandler
    );
    isSubscribed.value = true;
  };

  const unsubscribeFromChat = (eventId: number) => {
    if (!isSubscribed.value || typeof window === "undefined" || !(window as any).MessageBus) return;

    if (messageBusHandler) {
      (window as any).MessageBus.unsubscribe(
        `/live/event/${eventId}`,
        messageBusHandler
      );
      messageBusHandler = null;
    }
    isSubscribed.value = false;
  };

  return {
    messages,
    loadMessages,
    sendMessage,
    deleteMessage,
    subscribeToChat,
    unsubscribeFromChat,
  };
}
