import { defineComponent, h, onMounted, onUnmounted, ref } from "vue";
import { useSiteSettings } from "@cinelartv/core";

declare global {
  interface Window {
    googletag: any;
  }
}

export default defineComponent({
  name: "GoogleAdManager",
  props: {
    placement: { type: String, required: true },
  },
  setup(props) {
    const { siteSettings } = useSiteSettings();
    const slotId = `gpt-ad-${props.placement}-${Date.now()}`;
    const loaded = ref(false);

    const networkCode = siteSettings.value?.cinelar_ads_admanager_network_code;
    const adUnit = siteSettings.value?.[`cinelar_ads_admanager_${props.placement}`];

    const loadGPT = () => {
      if (!networkCode || !adUnit) return;

      // Load GPT script
      if (!document.querySelector('script[src*="googletagservices"]')) {
        const script = document.createElement("script");
        script.src = "https://www.googletagservices.com/tag/js/gpt.js";
        script.async = true;
        document.head.appendChild(script);
        script.onload = defineSlot;
      } else if (window.googletag?.cmd) {
        defineSlot();
      }
    };

    const defineSlot = () => {
      window.googletag = window.googletag || { cmd: [] };
      window.googletag.cmd.push(() => {
        const mapping = window.googletag
          .sizeMapping()
          .addSize([0, 0], [320, 50])
          .addSize([768, 0], [728, 90])
          .addSize([1024, 0], [970, 90])
          .build();

        window.googletag
          .defineSlot(`/${networkCode}/${adUnit}`, "fluid", slotId)
          .setTargeting("placement", [props.placement])
          .addService(window.googletag.pubads());

        window.googletag.pubads().enableSingleRequest();
        window.googletag.enableServices();
        window.googletag.display(slotId);
        loaded.value = true;
      });
    };

    onMounted(() => {
      loadGPT();
    });

    onUnmounted(() => {
      if (window.googletag && loaded.value) {
        window.googletag.cmd.push(() => {
          window.googletag.destroySlots([slotId]);
        });
      }
    });

    return () => {
      if (!networkCode || !adUnit) return null;

      return h("div", {
        id: slotId,
        class: "cinelar-ads-admanager",
      });
    };
  },
});
