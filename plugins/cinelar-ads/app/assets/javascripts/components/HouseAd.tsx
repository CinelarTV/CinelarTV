import { defineComponent, h, computed, onMounted, ref } from "vue";
import { useCurrentUser } from "@cinelartv/core";
import { ajax } from "@/lib/Ajax";

export default defineComponent({
  name: "HouseAd",
  props: {
    placement: { type: String, required: true },
    categoryId: { type: Number, default: undefined },
    contentType: { type: String, default: undefined },
    houseCreatives: { type: Object, default: () => ({}) },
  },
  setup(props) {
    const currentUser = useCurrentUser();
    const rotationIndex = ref(Math.floor(Math.random() * 100));

    const slotAds = computed(() => {
      const slot = props.houseCreatives?.[props.placement];
      if (!slot?.ads) return [];
      return slot.ads;
    });

    const currentAd = computed(() => {
      if (slotAds.value.length === 0) return null;
      const idx = rotationIndex.value % slotAds.value.length;
      return slotAds.value[idx];
    });

    const isVisible = computed(() => {
      if (!currentAd.value) return false;
      const user = currentUser.value;
      if (!user && !currentAd.value.visible_to_anons) return false;
      if (user && !currentAd.value.visible_to_logged_in_users) return false;
      return true;
    });

    return () => {
      if (!isVisible.value || !currentAd.value) return null;

      return h("div", {
        class: "cinelar-ads-house",
        innerHTML: currentAd.value.html,
      });
    };
  },
});
