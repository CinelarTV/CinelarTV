import { defineComponent, ref, onMounted } from "vue";
import { useRouter } from "vue-router";
import { useHead } from "unhead";
import { ajax } from "@/lib/Ajax";
import CTable, { type TableColumn } from "@/components/CTable";
import CButton from "@/components/forms/c-button";
import CSpinner from "@/components/c-spinner";
import CBadge from "@/components/CBadge";
import CIcon from "@/components/c-icon.vue";

interface HouseAd {
  id: number;
  name: string;
  visible_to_anons: boolean;
  visible_to_logged_in_users: boolean;
  impression_count?: number;
  click_count?: number;
  created_at: string;
}

export default defineComponent({
  name: "HouseAdsList",
  setup() {
    const router = useRouter();
    const ads = ref<HouseAd[]>([]);
    const loading = ref(true);

    useHead({ title: "House Ads — Admin" });

    const columns: TableColumn[] = [
      { key: "name", label: "Name", sortable: true },
      { key: "visibility", label: "Visibility" },
      { key: "impressions", label: "Impressions", sortable: true, align: "right" },
      { key: "created_at", label: "Created", sortable: true, align: "right" },
      { key: "actions", label: "", width: "140px", align: "right" },
    ];

    const loadAds = async () => {
      loading.value = true;
      try {
        const result = await ajax("/cinelar_ads/house_ads.json");
        const data = result.data;
        ads.value = Array.isArray(data) ? data : (data?.house_ads || []);
      } catch (e) {
        console.error("Failed to load house ads:", e);
      } finally {
        loading.value = false;
      }
    };

    const deleteAd = async (ad: HouseAd) => {
      if (!confirm(`Are you sure you want to delete "${ad.name}"?`)) return;
      try {
        await ajax(`/cinelar_ads/house_ads/${ad.id}.json`, { method: "DELETE" });
        ads.value = ads.value.filter((a) => a.id !== ad.id);
      } catch (e) {
        console.error("Failed to delete house ad:", e);
      }
    };

    onMounted(loadAds);

    return () => (
      <div class="admin-house-ads">
        <header class="admin-house-ads__hero">
          <div class="admin-house-ads__hero-header">
            <div>
              <p class="admin-house-ads__eyebrow">Admin Console</p>
              <h1 class="admin-house-ads__title">
                <CIcon icon="rectangle-ad" size={28} /> House Ads
              </h1>
              <p class="admin-house-ads__subtitle">
                Create and manage your own ad creatives
              </p>
            </div>
            <div class="admin-house-ads__hero-actions">
              <CButton
                icon="plus"
                onClick={() => router.push({ name: "admin.ads.house-ads.new" })}
              >
                New House Ad
              </CButton>
            </div>
          </div>
        </header>

        <section class="admin-house-ads__card">
          {loading.value ? (
            <div class="admin-house-ads__loading">
              <CSpinner />
            </div>
          ) : (
            <CTable
              columns={columns}
              data={ads.value}
              emptyText="No house ads created yet."
              v-slots={{
                "cell-name": ({ row }: { row: HouseAd }) => (
                  <span class="font-medium text-white">{row.name}</span>
                ),
                "cell-visibility": ({ row }: { row: HouseAd }) => (
                  <div class="flex gap-1">
                    {row.visible_to_anons && (
                      <CBadge variant="info" size="sm">Anons</CBadge>
                    )}
                    {row.visible_to_logged_in_users && (
                      <CBadge variant="success" size="sm">Logged-in</CBadge>
                    )}
                  </div>
                ),
                "cell-impressions": ({ row }: { row: HouseAd }) => (
                  <span class="text-white/60 text-sm">
                    {(row.impression_count || 0).toLocaleString()}
                  </span>
                ),
                "cell-created_at": ({ row }: { row: HouseAd }) => (
                  <span class="text-white/60 text-sm">
                    {new Date(row.created_at).toLocaleDateString()}
                  </span>
                ),
                "cell-actions": ({ row }: { row: HouseAd }) => (
                  <div class="flex gap-2 justify-end">
                    <CButton
                      variant="ghost"
                      size="sm"
                      icon="pencil"
                      onClick={() =>
                        router.push({
                          name: "admin.ads.house-ads.edit",
                          params: { id: row.id },
                        })
                      }
                    />
                    <CButton
                      variant="danger"
                      size="sm"
                      icon="trash-2"
                      onClick={() => deleteAd(row)}
                    />
                  </div>
                ),
              }}
            />
          )}
        </section>
      </div>
    );
  },
});
