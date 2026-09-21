import { defineComponent, h, onMounted, onUnmounted, ref } from "vue";
import { ajax } from "@/lib/Ajax";

export default defineComponent({
  name: "AdImpressionTracker",
  props: {
    placement: { type: String, required: true },
    adType: { type: String, required: true },
    houseAdId: { type: Number, default: undefined },
  },
  setup(props, { slots }) {
    const containerRef = ref<HTMLDivElement>();
    let impressionId: number | null = null;
    let observer: IntersectionObserver | null = null;

    const trackImpression = async () => {
      try {
        const result = await ajax("/cinelar_ads/ad_impressions.json", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          data: JSON.stringify({
            ad_type: props.adType,
            placement: props.placement,
            house_ad_id: props.houseAdId,
          }),
        });
        impressionId = result?.data?.id || null;
      } catch {
        // Silently fail
      }
    };

    const trackClick = async () => {
      if (!impressionId) return;
      try {
        await ajax(`/cinelar_ads/ad_impressions/${impressionId}/track_click.json`, {
          method: "PATCH",
        });
      } catch {
        // Silently fail
      }
    };

    onMounted(() => {
      if (!containerRef.value) return;

      // IntersectionObserver for impression tracking
      observer = new IntersectionObserver(
        (entries) => {
          entries.forEach((entry) => {
            if (entry.isIntersecting && impressionId === null) {
              trackImpression();
            }
          });
        },
        { threshold: 0.5 }
      );

      observer.observe(containerRef.value);

      // Click tracking
      containerRef.value.addEventListener("click", trackClick);
    });

    onUnmounted(() => {
      observer?.disconnect();
      containerRef.value?.removeEventListener("click", trackClick);
    });

    return () =>
      h("div", { ref: containerRef, class: "cinelar-ads-tracked" }, slots.default?.());
  },
});
