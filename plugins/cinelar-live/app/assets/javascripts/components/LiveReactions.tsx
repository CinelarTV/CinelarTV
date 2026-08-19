import { defineComponent, ref, onMounted, onUnmounted } from "vue";
import { useLiveReactions } from "../services/live-reactions-service";

const EMOJIS = ["❤️", "😂", "👍", "🔥", "😮", "💯"];

export default defineComponent({
  name: "LiveReactions",
  props: {
    eventId: { type: Number, required: true },
  },
  setup(props) {
    const { activeReactions, sendReaction, subscribeToReactions, unsubscribeFromReactions } =
      useLiveReactions();

    const lastSent = ref<Record<string, number>>({});

    const handleReaction = (emoji: string) => {
      const now = Date.now();
      if (lastSent.value[emoji] && now - lastSent.value[emoji] < 500) return;
      lastSent.value[emoji] = now;
      sendReaction(props.eventId, emoji);
    };

    onMounted(() => {
      subscribeToReactions(props.eventId);
    });

    onUnmounted(() => {
      unsubscribeFromReactions(props.eventId);
    });

    return () => (
      <div class="absolute bottom-20 left-1/2 -translate-x-1/2 z-[90] pointer-events-none">
        <div class="pointer-events-auto flex items-center gap-1 bg-black/40 backdrop-blur-sm rounded-full px-3 py-1.5 border border-white/10">
          {EMOJIS.map((emoji) => (
            <button
              key={emoji}
              onClick={() => handleReaction(emoji)}
              class="w-8 h-8 flex items-center justify-center text-lg hover:bg-white/10 rounded-full transition-colors hover:scale-110 active:scale-95"
            >
              {emoji}
            </button>
          ))}
        </div>

        <div class="absolute bottom-full left-0 right-0 h-[200px] pointer-events-none overflow-hidden">
          {activeReactions.value.map((reaction) => (
            <span
              key={reaction.id}
              class="reaction-float absolute bottom-0 text-2xl"
              style={{ left: `${reaction.x}%` }}
            >
              {reaction.emoji}
            </span>
          ))}
        </div>
      </div>
    );
  },
});
