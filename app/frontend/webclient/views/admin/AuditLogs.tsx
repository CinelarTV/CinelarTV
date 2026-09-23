import { defineComponent, ref, reactive, onMounted, computed } from "vue";
import { useHead } from "unhead";
import { ajax } from "../../lib/Ajax";
import CIcon from "@/components/c-icon.vue";
import CButton from "@/components/forms/c-button";
import CInput from "@/components/forms/c-input.vue";
import CSelect from "@/components/forms/c-select.vue";
import CBadge from "@/components/CBadge";
import CSkeleton from "@/components/CSkeleton";
import CAlert from "@/components/CAlert";

interface AuditLogUser {
  id: number;
  username: string;
  email: string;
}

interface AuditLog {
  id: number;
  action: number;
  action_label: string;
  custom_type: string | null;
  subject: string | null;
  description: string | null;
  previous_value: string | null;
  new_value: string | null;
  details: string | null;
  source: string | null;
  result: string | null;
  context: string | null;
  user: AuditLogUser | null;
  target_user: AuditLogUser | null;
  auditable_type: string | null;
  auditable_id: number | null;
  ip_address: string | null;
  created_at: string;
}

interface AuditLogMeta {
  total: number;
  page: number;
  per_page: number;
  total_pages: number;
}

const SOURCE_OPTIONS: { label: string; value: string }[] = [
  { label: "All Sources", value: "" },
  { label: "Web", value: "web" },
  { label: "API", value: "api" },
  { label: "System", value: "system" },
  { label: "Plugin", value: "plugin" },
];

function relativeTime(dateStr?: string): string {
  if (!dateStr) return "-";
  const d = new Date(dateStr);
  if (Number.isNaN(d.getTime())) return "-";
  const now = Date.now();
  const diff = now - d.getTime();
  const minutes = Math.floor(diff / 60000);
  if (minutes < 1) return "just now";
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  if (days < 30) return `${days}d ago`;
  const months = Math.floor(days / 30);
  if (months < 12) return `${months}mo ago`;
  return `${Math.floor(months / 12)}y ago`;
}

function sourceBadgeVariant(source: string | null): "primary" | "accent" | "warning" | "muted" {
  if (source === "web") return "primary";
  if (source === "api") return "accent";
  if (source === "system") return "warning";
  return "muted";
}

function formatDetails(details: string | null): string {
  if (!details) return "";
  try {
    const parsed = typeof details === "string" ? JSON.parse(details) : details;
    return JSON.stringify(parsed, null, 2);
  } catch {
    return details;
  }
}

export default defineComponent({
  name: "AdminAuditLogs",
  setup() {
    const logs = ref<AuditLog[]>([]);
    const meta = ref<AuditLogMeta | null>(null);
    const loading = ref(false);
    const expandedId = ref<number | null>(null);
    const actionTypes = ref<Record<string, string>>({});
    const currentPage = ref(1);

    const filters = reactive({
      action_type: "",
      user_id: "",
      source: "",
      from: "",
      to: "",
    });

    const visiblePages = computed(() => {
      if (!meta.value) return [];
      const { page, total_pages } = meta.value;
      if (total_pages <= 7) {
        return Array.from({ length: total_pages }, (_, i) => i + 1);
      }
      const pages: (number | string)[] = [];
      if (page <= 4) {
        for (let i = 1; i <= 5; i++) pages.push(i);
        pages.push("...", total_pages);
      } else if (page >= total_pages - 3) {
        pages.push(1, "...");
        for (let i = total_pages - 4; i <= total_pages; i++) pages.push(i);
      } else {
        pages.push(1, "...", page - 1, page, page + 1, "...", total_pages);
      }
      return pages;
    });

    const hasActiveFilters = computed(() =>
      filters.action_type || filters.user_id || filters.source || filters.from || filters.to
    );

    const actionOptions = computed(() => {
      const opts: { label: string; value: string }[] = [{ label: "All Actions", value: "" }];
      for (const [key, label] of Object.entries(actionTypes.value)) {
        opts.push({ label, value: key });
      }
      return opts;
    });

    const fetchLogs = async () => {
      loading.value = true;
      try {
        const params: Record<string, any> = { page: currentPage.value, per_page: 50 };
        if (filters.action_type) params.action_type = filters.action_type;
        if (filters.user_id) params.user_id = filters.user_id;
        if (filters.source) params.source = filters.source;
        if (filters.from) params.from = filters.from;
        if (filters.to) params.to = filters.to;

        const response = await ajax.get("/admin/audit-logs.json", { params });
        logs.value = response.data.data;
        meta.value = response.data.meta;
      } catch (error) {
        console.error("Failed to fetch audit logs:", error);
      } finally {
        loading.value = false;
      }
    };

    const fetchActionTypes = async () => {
      try {
        const response = await ajax.get("/admin/audit-logs/actions.json");
        actionTypes.value = response.data.actions || {};
      } catch (error) {
        console.error("Failed to fetch action types:", error);
      }
    };

    const applyFilters = () => {
      currentPage.value = 1;
      fetchLogs();
    };

    const clearFilters = () => {
      filters.action_type = "";
      filters.user_id = "";
      filters.source = "";
      filters.from = "";
      filters.to = "";
      currentPage.value = 1;
      fetchLogs();
    };

    const goToPage = (page: number) => {
      currentPage.value = page;
      expandedId.value = null;
      fetchLogs();
    };

    const toggleDetail = (id: number) => {
      expandedId.value = expandedId.value === id ? null : id;
    };

    onMounted(() => {
      fetchLogs();
      fetchActionTypes();
    });

    useHead({ title: "Audit Logs" });

    return () => (
      <div class="audit-logs-container">
        <header class="audit-logs__header">
          <div class="audit-logs__header-content">
            <h1 class="audit-logs__title">
              <CIcon icon="gavel" size={24} />
              Audit Logs
            </h1>
            <p class="audit-logs__subtitle">
              Track and review all administrative actions performed in the system.
            </p>
          </div>
          <div class="audit-logs__header-actions">
            <CButton icon="refresh-cw" loading={loading.value} onClick={fetchLogs}>
              Refresh
            </CButton>
          </div>
        </header>

        <section class="audit-logs__card">
          <div class="audit-logs__filters">
            <div class="audit-logs__filter">
              <label class="audit-logs__filter-label">Action</label>
              <CSelect
                options={actionOptions.value}
                modelValue={filters.action_type}
                onUpdate:modelValue={(val: string) => {
                  filters.action_type = val;
                  applyFilters();
                }}
              />
            </div>

            <div class="audit-logs__filter">
              <label class="audit-logs__filter-label">User ID</label>
              <CInput
                modelValue={filters.user_id}
                onUpdate:modelValue={(val: string) => { filters.user_id = val; }}
                placeholder="User ID..."
                onKeyup={(e: KeyboardEvent) => {
                  if (e.key === "Enter") applyFilters();
                }}
              />
            </div>

            <div class="audit-logs__filter">
              <label class="audit-logs__filter-label">Source</label>
              <CSelect
                options={SOURCE_OPTIONS}
                modelValue={filters.source}
                onUpdate:modelValue={(val: string) => {
                  filters.source = val;
                  applyFilters();
                }}
              />
            </div>

            <div class="audit-logs__filter">
              <label class="audit-logs__filter-label">From</label>
              <CInput
                type="date"
                modelValue={filters.from}
                onUpdate:modelValue={(val: string) => {
                  filters.from = val;
                  applyFilters();
                }}
              />
            </div>

            <div class="audit-logs__filter">
              <label class="audit-logs__filter-label">To</label>
              <CInput
                type="date"
                modelValue={filters.to}
                onUpdate:modelValue={(val: string) => {
                  filters.to = val;
                  applyFilters();
                }}
              />
            </div>

            {hasActiveFilters.value && (
              <div class="audit-logs__filter audit-logs__filter--actions">
                <CButton variant="ghost" icon="x" onClick={clearFilters}>
                  Clear
                </CButton>
              </div>
            )}
          </div>
        </section>

        {loading.value && logs.value.length === 0 ? (
          <section class="audit-logs__card">
            <CSkeleton variant="avatar-text" count={6} />
          </section>
        ) : logs.value.length === 0 ? (
          <section class="audit-logs__card">
            <CAlert type="info">
              No audit logs found{hasActiveFilters.value ? " matching the current filters" : ""}.
            </CAlert>
          </section>
        ) : (
          <>
            <section class="audit-logs__card audit-logs__card--table">
              <table class="audit-logs__table">
                <thead>
                  <tr>
                    <th class="audit-logs__th">User</th>
                    <th class="audit-logs__th">Action</th>
                    <th class="audit-logs__th">Subject</th>
                    <th class="audit-logs__th">When</th>
                    <th class="audit-logs__th">Source</th>
                    <th class="audit-logs__th">Context</th>
                  </tr>
                </thead>
                <tbody>
                  {logs.value.map(log => (
                    <tr
                      key={log.id}
                      class={`audit-logs__row ${expandedId.value === log.id ? "audit-logs__row--expanded" : ""}`}
                      onClick={() => toggleDetail(log.id)}
                    >
                      <td class="audit-logs__td">
                        {log.user ? (
                          <div class="audit-logs__user">
                            <span class="audit-logs__username">{log.user.username}</span>
                            <span class="audit-logs__user-email">{log.user.email}</span>
                          </div>
                        ) : (
                          <span class="audit-logs__user audit-logs__user--system">System</span>
                        )}
                      </td>
                      <td class="audit-logs__td">
                        <CBadge variant={sourceBadgeVariant(log.source)} dot>
                          {log.action_label}
                        </CBadge>
                      </td>
                      <td class="audit-logs__td audit-logs__td--subject" title={log.subject || log.description || ""}>
                        {log.subject || log.description || "-"}
                      </td>
                      <td class="audit-logs__td audit-logs__td--time" title={log.created_at}>
                        {relativeTime(log.created_at)}
                      </td>
                      <td class="audit-logs__td">
                        {log.source ? <CBadge variant="muted">{log.source}</CBadge> : "-"}
                      </td>
                      <td class="audit-logs__td audit-logs__td--context" title={log.context || ""}>
                        {log.context || "-"}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </section>

            {logs.value.map(log => (
              expandedId.value === log.id ? (
                <section key={`detail-${log.id}`} class="audit-logs__card audit-logs__detail">
                  <div class="audit-logs__detail-grid">
                    {log.target_user && (
                      <div class="audit-logs__detail-item">
                        <span class="audit-logs__detail-label">Target User</span>
                        <span class="audit-logs__detail-value">
                          {log.target_user.username} ({log.target_user.email})
                        </span>
                      </div>
                    )}
                    {log.previous_value && (
                      <div class="audit-logs__detail-item">
                        <span class="audit-logs__detail-label">Previous Value</span>
                        <span class="audit-logs__detail-value audit-logs__detail-value--code">
                          {log.previous_value}
                        </span>
                      </div>
                    )}
                    {log.new_value && (
                      <div class="audit-logs__detail-item">
                        <span class="audit-logs__detail-label">New Value</span>
                        <span class="audit-logs__detail-value audit-logs__detail-value--code">
                          {log.new_value}
                        </span>
                      </div>
                    )}
                    {log.ip_address && (
                      <div class="audit-logs__detail-item">
                        <span class="audit-logs__detail-label">IP Address</span>
                        <span class="audit-logs__detail-value">{log.ip_address}</span>
                      </div>
                    )}
                    {log.auditable_type && (
                      <div class="audit-logs__detail-item">
                        <span class="audit-logs__detail-label">Resource</span>
                        <span class="audit-logs__detail-value">
                          {log.auditable_type} #{log.auditable_id}
                        </span>
                      </div>
                    )}
                    {log.result && (
                      <div class="audit-logs__detail-item">
                        <span class="audit-logs__detail-label">Result</span>
                        <span class="audit-logs__detail-value">{log.result}</span>
                      </div>
                    )}
                    {log.details && (
                      <div class="audit-logs__detail-item audit-logs__detail-item--full">
                        <span class="audit-logs__detail-label">Details</span>
                        <pre class="audit-logs__detail-pre">{formatDetails(log.details)}</pre>
                      </div>
                    )}
                  </div>
                </section>
              ) : null
            ))}
          </>
        )}

        {!loading.value && meta.value && meta.value.total_pages > 1 && (
          <div class="audit-logs__pagination">
            <button
              class="audit-logs__page-btn"
              disabled={meta.value.page <= 1}
              onClick={() => goToPage(1)}
            >
              <CIcon icon="chevrons-left" size={16} />
            </button>
            <button
              class="audit-logs__page-btn"
              disabled={meta.value.page <= 1}
              onClick={() => goToPage(meta.value!.page - 1)}
            >
              <CIcon icon="chevron-left" size={16} />
            </button>

            {visiblePages.value.map((p, i) =>
              typeof p === "string" ? (
                <span key={`ellipsis-${i}`} class="audit-logs__page-ellipsis">...</span>
              ) : (
                <button
                  key={p}
                  class={`audit-logs__page-btn audit-logs__page-btn--number ${p === meta.value!.page ? "audit-logs__page-btn--active" : ""}`}
                  onClick={() => goToPage(p)}
                >
                  {p}
                </button>
              )
            )}

            <button
              class="audit-logs__page-btn"
              disabled={meta.value.page >= meta.value.total_pages}
              onClick={() => goToPage(meta.value!.page + 1)}
            >
              <CIcon icon="chevron-right" size={16} />
            </button>
            <button
              class="audit-logs__page-btn"
              disabled={meta.value.page >= meta.value.total_pages}
              onClick={() => goToPage(meta.value!.total_pages)}
            >
              <CIcon icon="chevrons-right" size={16} />
            </button>

            <span class="audit-logs__page-info">
              Page {meta.value.page} of {meta.value.total_pages} ({meta.value.total} records)
            </span>
          </div>
        )}
      </div>
    );
  },
});
