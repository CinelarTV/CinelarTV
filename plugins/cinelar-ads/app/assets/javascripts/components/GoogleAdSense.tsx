import { defineComponent, h, onMounted, onUnmounted, ref } from "vue";
import { useSiteSettings } from "@cinelartv/core";

declare global {
  interface Window {
    adsbygoogle: any[];
  }
}

export default defineComponent({
  name: "GoogleAdSense",
  props: {
    placement: { type: String, required: true },
  },
  setup(props) {
    const { siteSettings } = useSiteSettings();
    const containerRef = ref<HTMLDivElement>();

    const publisherId = siteSettings.value?.cinelar_ads_adsense_publisher_id;
    const adUnitCode = siteSettings.value?.[`cinelar_ads_adsense_${props.placement}`];

    const loadAdSense = () => {
      if (!publisherId || !adUnitCode) return;

      // Load AdSense script if not already loaded
      if (!document.querySelector(`script[src*="adsbygoogle"]`)) {
        const script = document.createElement("script");
        script.src = `https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${publisherId}`;
        script.async = true;
        document.head.appendChild(script);
      }

      // Push ad
      try {
        (window.adsbygoogle = window.adsbygoogle || []).push({});
      } catch (e) {
        console.error("[cinelar-ads] AdSense error:", e);
      }
    };

    onMounted(() => {
      loadAdSense();
    });

    return () => {
      if (!publisherId || !adUnitCode) return null;

      return h("div", { ref: containerRef, class: "cinelar-ads-adsense" }, [
        h("ins", {
          class: "adsbygoogle",
          style: "display:block",
          "data-ad-client": publisherId,
          "data-ad-slot": adUnitCode,
          "data-ad-format": "auto",
          "data-full-width-responsive": "true",
        }),
      ]);
    };
  },
});
