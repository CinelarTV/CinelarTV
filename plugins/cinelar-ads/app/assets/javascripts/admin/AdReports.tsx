import { defineComponent, ref, onMounted } from "vue";
import { useHead } from "unhead";
import { ajax } from "@/lib/Ajax";
import CTable, { type TableColumn } from "@/components/CTable";
import CStatCard from "@/components/CStatCard";
import CSpinner from "@/components/c-spinner";
import CAlert from "@/components/CAlert";
import CTabs, { type TabItem } from "@/components/CTabs";
import CIcon from "@/components/c-icon.vue";

interface ReportData {
  total_impressions: number;
  total_clicks: number;
  by_type: Record<string, number>;
  by_placement: Record<string, number>;
  ctr_by_type: Record<string, number>;
  ctr_by_placement: Record<string, number>;
  top_house_ads: Record<string, number>;
}

const PLACEMENT_LABELS: Record<string, string> = {
  home_before_carousel: "Home — Before Carousel",
  home_after_carousel: "Home — After Carousel",
  home_between_rows: "Home — Between Rows",
  content_below_actions: "Content — Below Actions",
  content_below_related: "Content — Below Related",
  explore_top: "Explore — Top",
};

export default defineComponent({
  name: "AdReports",
  setup() {
    const report = ref<ReportData | null>(null);
    const loading = ref(true);
    const period = ref(30);
    const activeTab = ref("by-type");

    useHead({ title: "Ad Reports — Admin" });

    const tabItems: TabItem[] = [
      { key: "by-type", label: "By Ad Type" },
      { key: "by-placement", label: "By Placement" },
      { key: "top-ads", label: "Top House Ads" },
    ];

    const typeColumns: TableColumn[] = [
      { key: "type", label: "Type" },
      { key: "impressions", label: "Impressions", sortable: true, align: "right" },
      { key: "ctr", label: "CTR", align: "right" },
    ];

    const placementColumns: TableColumn[] = [
      { key: "placement", label: "Placement" },
      { key: "impressions", label: "Impressions", sortable: true, align: "right" },
      { key: "ctr", label: "CTR", align: "right" },
    ];

    const topAdsColumns: TableColumn[] = [
      { key: "name", label: "Ad Name" },
      { key: "impressions", label: "Impressions", sortable: true, align: "right" },
    ];

    const loadReport = async () => {
      loading.value = true;
      try {
        const result = await ajax(`/cinelar_ads/reports.json?period=${period.value}`);
        report.value = result.data;
      } catch (e) {
        console.error("Failed to load report:", e);
      } finally {
        loading.value = false;
      }
    };

    const typeData = () => {
      if (!report.value) return [];
      return Object.entries(report.value.by_type).map(([type, count]) => ({
        type,
        impressions: count,
        ctr: `${report.value!.ctr_by_type[type] || 0}%`,
      }));
    };

    const placementData = () => {
      if (!report.value) return [];
      return Object.entries(report.value.by_placement).map(([placement, count]) => ({
        placement: PLACEMENT_LABELS[placement] || placement,
        impressions: count,
        ctr: `${report.value!.ctr_by_placement[placement] || 0}%`,
      }));
    };

    const topAdsData = () => {
      if (!report.value) return [];
      return Object.entries(report.value.top_house_ads).map(([name, count]) => ({
        name,
        impressions: count,
      }));
    };

    onMounted(loadReport);

    return () => (
      <div class="admin-ads-reports">
        <header class="admin-ads-reports__hero">
          <div class="admin-ads-reports__hero-header">
            <div>
              <p class="admin-ads-reports__eyebrow">Admin Console</p>
              <h1 class="admin-ads-reports__title">
                <CIcon icon="bar-chart-2" size={28} /> Ad Reports
              </h1>
              <p class="admin-ads-reports__subtitle">
                Impression and click analytics
              </p>
            </div>
            <div class="admin-ads-reports__hero-actions">
              <select
                class="c-input"
                value={period.value}
                onChange={(e: any) => {
                  period.value = Number(e.target.value);
                  loadReport();
                }}
              >
                <option value={7}>Last 7 days</option>
                <option value={30}>Last 30 days</option>
                <option value={90}>Last 90 days</option>
              </select>
            </div>
          </div>
        </header>

        <section class="admin-ads-reports__card">
          {loading.value ? (
            <div class="admin-ads-reports__loading">
              <CSpinner />
            </div>
          ) : report.value ? (
            <>
              <div class="grid grid-cols-3 gap-4 mb-6">
                <CStatCard
                  label="Total Impressions"
                  value={report.value.total_impressions.toLocaleString()}
                  icon="eye"
                  color="primary"
                />
                <CStatCard
                  label="Total Clicks"
                  value={report.value.total_clicks.toLocaleString()}
                  icon="mouse-pointer-click"
                  color="success"
                />
                <CStatCard
                  label="Overall CTR"
                  value={
                    report.value.total_impressions > 0
                      ? `${((report.value.total_clicks / report.value.total_impressions) * 100).toFixed(2)}%`
                      : "0%"
                  }
                  icon="percent"
                  color="info"
                />
              </div>

              <CTabs
                modelValue={activeTab.value}
                onUpdate:modelValue={(v: string) => (activeTab.value = v)}
                items={tabItems}
                variant="underline"
              />

              <div class="mt-4">
                {activeTab.value === "by-type" && (
                  <CTable
                    columns={typeColumns}
                    data={typeData()}
                    emptyText="No data available."
                  />
                )}
                {activeTab.value === "by-placement" && (
                  <CTable
                    columns={placementColumns}
                    data={placementData()}
                    emptyText="No data available."
                  />
                )}
                {activeTab.value === "top-ads" && (
                  <CTable
                    columns={topAdsColumns}
                    data={topAdsData()}
                    emptyText="No data available."
                  />
                )}
              </div>
            </>
          ) : (
            <CAlert type="info">
              No data available for the selected period.
            </CAlert>
          )}
        </section>
      </div>
    );
  },
});
