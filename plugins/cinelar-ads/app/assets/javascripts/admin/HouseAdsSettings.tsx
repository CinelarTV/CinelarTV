import { defineComponent, ref, onMounted } from "vue";
import { useHead } from "unhead";
import { ajax } from "@/lib/Ajax";
import CFormRow from "@/components/forms/CFormRow";
import CInput from "@/components/forms/c-input.vue";
import CButton from "@/components/forms/c-button";
import CSpinner from "@/components/c-spinner";
import CAlert from "@/components/CAlert";
import CBadge from "@/components/CBadge";
import CIcon from "@/components/c-icon.vue";

interface SlotSetting {
  slot: string;
  ad_names: string;
  ads: string[];
}

const SLOT_LABELS: Record<string, string> = {
  home_before_carousel: "Homepage — Before Carousel",
  home_after_carousel: "Homepage — After Carousel",
  home_between_rows: "Homepage — Between Content Rows",
  content_below_actions: "Content Detail — Below Actions",
  content_below_related: "Content Detail — Below Related Content",
  explore_top: "Explore Page — Top",
};

export default defineComponent({
  name: "HouseAdsSettings",
  setup() {
    const settings = ref<SlotSetting[]>([]);
    const loading = ref(true);
    const saving = ref(false);
    const success = ref("");

    useHead({ title: "Ad Slot Settings — Admin" });

    const loadSettings = async () => {
      try {
        const result = await ajax("/cinelar_ads/settings.json");
        settings.value = result.data || [];
      } catch (e) {
        console.error("Failed to load settings:", e);
      } finally {
        loading.value = false;
      }
    };

    const saveSlot = async (slot: SlotSetting) => {
      saving.value = true;
      success.value = "";
      try {
        await ajax("/cinelar_ads/settings.json", {
          method: "PUT",
          headers: { "Content-Type": "application/json" },
          data: JSON.stringify({ slot: slot.slot, ad_names: slot.ad_names }),
        });
        success.value = `${SLOT_LABELS[slot.slot] || slot.slot} saved.`;
        setTimeout(() => (success.value = ""), 3000);
      } catch (e) {
        console.error("Failed to save slot:", e);
      } finally {
        saving.value = false;
      }
    };

    onMounted(loadSettings);

    return () => (
      <div class="admin-ads-settings">
        <header class="admin-ads-settings__hero">
          <div class="admin-ads-settings__hero-header">
            <div>
              <p class="admin-ads-settings__eyebrow">Admin Console</p>
              <h1 class="admin-ads-settings__title">
                <CIcon icon="sliders" size={28} /> Ad Slot Settings
              </h1>
              <p class="admin-ads-settings__subtitle">
                Assign house ads to display slots. Separate multiple ad names with | (pipe).
              </p>
            </div>
          </div>
        </header>

        <section class="admin-ads-settings__card">
          {loading.value ? (
            <div class="admin-ads-settings__loading">
              <CSpinner />
            </div>
          ) : (
            <>
              {success.value && (
                <CAlert type="success" title="Saved" dismissible>
                  {success.value}
                </CAlert>
              )}

              <div class="flex flex-col gap-4">
                {settings.value.map((slot) => (
                  <div
                    key={slot.slot}
                    class="p-4 bg-white/[0.03] border border-white/6 rounded-lg"
                  >
                    <div class="flex items-center justify-between mb-3">
                      <h3 class="text-sm font-medium text-white">
                        {SLOT_LABELS[slot.slot] || slot.slot}
                      </h3>
                      <CButton
                        variant="ghost"
                        size="sm"
                        icon="check"
                        loading={saving.value}
                        onClick={() => saveSlot(slot)}
                      >
                        Save
                      </CButton>
                    </div>

                    <CFormRow hint="Separate multiple ad names with | (pipe)">
                      <CInput
                        modelValue={slot.ad_names}
                        onUpdate:modelValue={(v: string) => (slot.ad_names = v)}
                        placeholder="Ad Name 1|Ad Name 2"
                      />
                    </CFormRow>

                    {slot.ads.length > 0 && (
                      <div class="flex gap-1 mt-2">
                        <span class="text-white/40 text-xs">Active:</span>
                        {slot.ads.map((ad) => (
                          <CBadge key={ad} variant="info" size="sm">
                            {ad}
                          </CBadge>
                        ))}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </>
          )}
        </section>
      </div>
    );
  },
});
