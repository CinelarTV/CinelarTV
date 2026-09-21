import { defineComponent, h, onMounted, ref } from "vue";
import { useSiteSettings } from "@cinelartv/core";

export default defineComponent({
  name: "AdTerra",
  props: {
    placement: { type: String, required: true },
  },
  setup(props) {
    const { siteSettings } = useSiteSettings();
    const containerRef = ref<HTMLDivElement>();

    const getZoneId = (): string | null => {
      const zoneMap = siteSettings.value?.cinelar_ads_adterra_zone_ids;
      if (!zoneMap) return null;

      try {
        const parsed = typeof zoneMap === "string" ? JSON.parse(zoneMap) : zoneMap;
        return parsed[props.placement] || null;
      } catch {
        return null;
      }
    };

    const loadAdTerra = (zoneId: string) => {
      const script = document.createElement("script");
      script.src = `//www.profitablegate.com/key/${zoneId}/zone.js`;
      script.async = true;
      script.dataset.zoneId = zoneId;
      document.head.appendChild(script);
    };

    onMounted(() => {
      const zoneId = getZoneId();
      if (zoneId) {
        loadAdTerra(zoneId);
      }
    });

    return () => {
      const zoneId = getZoneId();
      if (!zoneId) return null;

      return h("div", {
        ref: containerRef,
        class: "cinelar-ads-adterra",
        "data-zone-id": zoneId,
      });
    };
  },
});
