import { ref } from "vue";

export interface Reaction {
  id: string;
  emoji: string;
  username: string;
  timestamp: number;
  x: number;
}

function csrfToken(): string {
  const el = document.querySelector('[name="csrf-token"]') as HTMLMetaElement;
  return el?.content || "";
}

const activeReactions = ref<Reaction[]>([]);
const isSubscribed = ref(false);
let messageBusHandler: ((data: any) => void) | null = null;

let reactionId = 0;

export function useLiveReactions() {
  const sendReaction = async (eventId: number, emoji: string) => {
    try {
      await fetch(`/community/events/${eventId}/reactions.json`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken(),
        },
        body: JSON.stringify({ emoji }),
      });
    } catch (e) {
      console.error("[LiveReactions] Failed to send reaction:", e);
    }
  };

  const subscribeToReactions = (eventId: number) => {
    if (isSubscribed.value) return;
    if (typeof window === "undefined" || !(window as any).MessageBus) return;

    messageBusHandler = (data: any) => {
      if (data.type === "reaction") {
        const reaction: Reaction = {
          id: `r-${++reactionId}-${Date.now()}`,
          emoji: data.emoji,
          username: data.username,
          timestamp: Date.now(),
          x: 10 + Math.random() * 80,
        };
        activeReactions.value.push(reaction);

        setTimeout(() => {
          activeReactions.value = activeReactions.value.filter(
            (r) => r.id !== reaction.id
          );
        }, 3000);
      }
    };

    (window as any).MessageBus.subscribe(
      `/live/event/${eventId}`,
      messageBusHandler
    );
    isSubscribed.value = true;
  };

  const unsubscribeFromReactions = (eventId: number) => {
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
    activeReactions,
    sendReaction,
    subscribeToReactions,
    unsubscribeFromReactions,
  };
}
