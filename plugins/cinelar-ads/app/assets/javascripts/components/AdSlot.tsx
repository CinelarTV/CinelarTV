import { defineComponent, h, computed, onMounted, ref } from "vue";
import { useSiteSettings } from "@cinelartv/core";
import { ajax } from "@/lib/Ajax";
import HouseAd from "./HouseAd";
import GoogleAdSense from "./GoogleAdSense";
import GoogleAdManager from "./GoogleAdManager";
import AdTerra from "./AdTerra";
import AdImpressionTracker from "./AdImpressionTracker";

interface AdSlotProps {
  placement: string;
  categoryId?: number;
  contentType?: string;
}

const AD_NETWORKS = [
  { key: "adsense", setting: "cinelar_ads_adsense_enabled", component: GoogleAdSense },
  { key: "admanager", setting: "cinelar_ads_admanager_enabled", component: GoogleAdManager },
  { key: "adterra", setting: "cinelar_ads_adterra_enabled", component: AdTerra },
];

export default defineComponent({
  name: "AdSlot",
  props: {
    placement: { type: String, default: "" },
    categoryId: { type: Number, default: undefined },
    contentType: { type: String, default: undefined },
  },
  setup(props: AdSlotProps) {
    const { siteSettings } = useSiteSettings();
    const houseCreatives = ref<any>(null);
    const loading = ref(true);

    const enabled = computed(() => siteSettings.value?.cinelar_ads_enabled ?? false);

    const excludedCategories = computed(() => {
      const excluded = siteSettings.value?.cinelar_ads_exclude_categories;
      if (!excluded || !Array.isArray(excluded)) return [];
      return excluded.map(Number);
    });

    const excludedContentTypes = computed(() => {
      const excluded = siteSettings.value?.cinelar_ads_exclude_content_types;
      if (!excluded || !Array.isArray(excluded)) return [];
      return excluded;
    });

    const isExcluded = computed(() => {
      if (props.categoryId && excludedCategories.value.includes(props.categoryId)) return true;
      if (props.contentType && excludedContentTypes.value.includes(props.contentType)) return true;
      return false;
    });

    const contender = computed(() => {
      if (!enabled.value || isExcluded.value) return null;

      // Check house ads first
      const houseFreq = siteSettings.value?.cinelar_ads_house_frequency ?? 100;
      const hasHouseAds = houseCreatives.value?.[props.placement]?.ads?.length > 0;

      if (hasHouseAds) {
        // Random roll against frequency
        if (Math.random() * 100 < houseFreq) {
          return { type: "house", component: HouseAd };
        }
      }

      // Check external networks
      for (const network of AD_NETWORKS) {
        const networkEnabled = siteSettings.value?.[network.setting];
        const slotSetting = `cinelar_ads_${network.key}_${props.placement}`;
        const slotValue = siteSettings.value?.[slotSetting];

        if (networkEnabled && slotValue) {
          return { type: network.key, component: network.component };
        }
      }

      // Fallback to house ads if available
      if (hasHouseAds) {
        return { type: "house", component: HouseAd };
      }

      return null;
    });

    onMounted(async () => {
      try {
        // GET /site.json — the SiteSerializer includes house_creatives injected
        // by the cinelar-ads plugin via register_serializer_extension.
        // The response body is a flat JSON object (no root key).
        const result = await ajax.get("/site.json");
        houseCreatives.value = result.data?.house_creatives || {};
      } catch {
        houseCreatives.value = {};
      } finally {
        loading.value = false;
      }
    });

    return () => {
      if (!enabled.value || loading.value || !contender.value) return null;

      const { type, component: AdComponent } = contender.value;

      return h(AdImpressionTracker, { placement: props.placement, adType: type }, () =>
        h(AdComponent, {
          placement: props.placement,
          categoryId: props.categoryId,
          contentType: props.contentType,
          houseCreatives: houseCreatives.value,
        })
      );
    };
  },
});
