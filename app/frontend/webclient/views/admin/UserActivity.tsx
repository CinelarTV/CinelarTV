import { defineComponent, ref, reactive, onMounted, computed, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useHead } from 'unhead';
import { ajax } from '../../lib/Ajax';
import CIcon from '@/components/c-icon.vue';
import CButton from '@/components/forms/c-button';
import CTabs, { type TabItem } from '@/components/CTabs';
import CBadge from '@/components/CBadge';
import CSkeleton from '@/components/CSkeleton';
import CPagination from '@/components/CPagination';

interface ActivityProfile {
  id: number;
  name: string;
  avatar_id: string | null;
}

interface ActivityContent {
  id: number;
  title: string;
  content_type: string;
  banner: any;
  cover: any;
}

interface ActivityItem {
  id: string;
  type: 'reproduction' | 'like' | 'dislike' | 'billing' | 'security';
  action: string;
  action_label: string;
  timestamp: string;
  profile: ActivityProfile | null;
  content: ActivityContent | null;
  metadata: Record<string, any>;
}

interface ActivityMeta {
  total: number;
  page: number;
  per_page: number;
  total_pages: number;
  counts: Record<string, number>;
  profiles: ActivityProfile[];
}

const AVATAR_COLORS = [
  '#6366f1', '#8b5cf6', '#a855f7', '#ec4899', '#ef4444',
  '#f97316', '#eab308', '#22c55e', '#14b8a6', '#06b6d4',
  '#3b82f6', '#6366f1'
];

function avatarColor(name: string): string {
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash);
  }
  return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

function relativeTime(dateStr?: string): string {
  if (!dateStr) return '-';
  const d = new Date(dateStr);
  if (Number.isNaN(d.getTime())) return '-';
  const now = Date.now();
  const diff = now - d.getTime();
  const minutes = Math.floor(diff / 60000);
  if (minutes < 1) return 'just now';
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  if (days < 30) return `${days}d ago`;
  const months = Math.floor(days / 30);
  if (months < 12) return `${months}mo ago`;
  return `${Math.floor(months / 12)}y ago`;
}

function activityTypeIcon(type: string): string {
  switch (type) {
    case 'reproduction': return 'play';
    case 'like': return 'thumbs-up';
    case 'dislike': return 'thumbs-down';
    case 'billing': return 'credit-card';
    case 'security': return 'shield';
    default: return 'activity';
  }
}

function activityTypeBadgeVariant(type: string): 'primary' | 'success' | 'danger' | 'warning' | 'accent' | 'muted' {
  switch (type) {
    case 'reproduction': return 'primary';
    case 'like': return 'success';
    case 'dislike': return 'danger';
    case 'billing': return 'warning';
    case 'security': return 'accent';
    default: return 'muted';
  }
}

function contentImageUrl(content: ActivityContent): string | null {
  const images = content.banner || content.cover;
  if (!images) return null;
  if (images.original?.webp) return images.original.webp;
  if (images.thumbnail?.webp) return images.thumbnail.webp;
  if (images.small?.webp) return images.small.webp;
  if (typeof images === 'string') return images;
  return null;
}

export default defineComponent({
  name: 'AdminUserActivity',
  setup() {
    const route = useRoute();
    const router = useRouter();
    const userId = route.params.id as string;

    const loading = ref(false);
    const items = ref<ActivityItem[]>([]);
    const meta = ref<ActivityMeta | null>(null);
    const activeType = ref('all');
    const selectedProfileId = ref<string>('');
    const currentPage = ref(1);

    const TAB_ITEMS: TabItem[] = [
      { key: 'all', label: 'All', icon: 'activity' },
      { key: 'reproduction', label: 'Reproductions', icon: 'play' },
      { key: 'like', label: 'Likes', icon: 'thumbs-up' },
      { key: 'dislike', label: 'Dislikes', icon: 'thumbs-down' },
      { key: 'billing', label: 'Billing', icon: 'credit-card' },
      { key: 'security', label: 'Security', icon: 'shield' },
    ];

    const profileOptions = computed(() => {
      const options = [{ label: 'All Profiles', value: '' }];
      if (meta.value?.profiles) {
        for (const p of meta.value.profiles) {
          options.push({ label: p.name, value: String(p.id) });
        }
      }
      return options;
    });

    const fetchActivity = async () => {
      loading.value = true;
      try {
        const params: Record<string, any> = {
          page: currentPage.value,
          per_page: 20,
        };
        if (activeType.value !== 'all') params.activity_type = activeType.value;
        if (selectedProfileId.value) params.profile_id = selectedProfileId.value;

        const res = await ajax.get(`/admin/users/${userId}/activity.json`, { params });
        items.value = res.data.data;
        meta.value = res.data.meta;
      } catch (e) {
        console.error(e);
      } finally {
        loading.value = false;
      }
    };

    const onTabChange = (key: string) => {
      activeType.value = key;
      currentPage.value = 1;
      fetchActivity();
    };

    const onProfileChange = () => {
      currentPage.value = 1;
      fetchActivity();
    };

    const onPageChange = (page: number) => {
      currentPage.value = page;
      fetchActivity();
    };

    const goBack = () => router.push(`/admin/users/${userId}`);

    onMounted(fetchActivity);

    useHead({ title: computed(() => `Activity - User #${userId}`) });

    return () => (
      <div class="user-activity-admin">
        <header class="user-activity-admin__hero">
          <div class="user-activity-admin__hero-top">
            <button class="user-activity-admin__back" onClick={goBack}>
              <CIcon icon="arrow-left" size={16} />
              Back to User
            </button>
          </div>
          <h1 class="user-activity-admin__title">
            <CIcon icon="activity" size={22} />
            User Activity
          </h1>
          {meta.value && (
            <div class="user-activity-admin__summary">
              <span class="user-activity-admin__summary-item">
                <strong>{meta.value.total}</strong> total events
              </span>
              {Object.entries(meta.value.counts).map(([key, count]) => (
                key !== 'all' ? (
                  <span class="user-activity-admin__summary-item" key={key}>
                    <CBadge variant={activityTypeBadgeVariant(key)}>{count} {key}</CBadge>
                  </span>
                ) : null
              ))}
            </div>
          )}
        </header>

        <div class="user-activity-admin__filters">
          <div class="user-activity-admin__tabs-wrap">
            <CTabs
              modelValue={activeType.value}
              items={TAB_ITEMS}
              variant="pills"
              size="sm"
              onUpdate:modelValue={onTabChange}
            />
          </div>
          {meta.value && meta.value.profiles.length > 1 && (
            <div class="user-activity-admin__profile-filter">
              <span class="user-activity-admin__filter-label">Profile:</span>
              <select
                class="user-activity-admin__select"
                value={selectedProfileId.value}
                onChange={(e: Event) => {
                  selectedProfileId.value = (e.target as HTMLSelectElement).value;
                  onProfileChange();
                }}
              >
                {profileOptions.value.map(opt => (
                  <option key={opt.value} value={opt.value}>{opt.label}</option>
                ))}
              </select>
            </div>
          )}
        </div>

        {loading.value ? (
          <div class="user-activity-admin__loading">
            <CSkeleton variant="avatar-text" count={5} />
          </div>
        ) : items.value.length === 0 ? (
          <div class="user-activity-admin__empty">
            <CIcon icon="activity" size={48} />
            <p>No activity found for the selected filters.</p>
          </div>
        ) : (
          <>
            <div class="user-activity-admin__timeline">
              {items.value.map(item => (
                <div class={`user-activity-admin__item user-activity-admin__item--${item.type}`} key={item.id}>
                  <div class="user-activity-admin__item-icon">
                    <CIcon icon={activityTypeIcon(item.type)} size={16} />
                  </div>
                  <div class="user-activity-admin__item-body">
                    <div class="user-activity-admin__item-header">
                      <div class="user-activity-admin__item-action">
                        <CBadge variant={activityTypeBadgeVariant(item.type)} icon={activityTypeIcon(item.type)}>
                          {item.action_label}
                        </CBadge>
                      </div>
                      <span class="user-activity-admin__item-time" title={item.timestamp}>
                        {relativeTime(item.timestamp)}
                      </span>
                    </div>

                    {item.profile && (
                      <div class="user-activity-admin__item-profile">
                        <div
                          class="user-activity-admin__mini-avatar"
                          style={{ backgroundColor: avatarColor(item.profile.name) }}
                        >
                          {item.profile.name.charAt(0).toUpperCase()}
                        </div>
                        <span>{item.profile.name}</span>
                      </div>
                    )}

                    {item.content && (
                      <div class="user-activity-admin__item-content">
                        {contentImageUrl(item.content) ? (
                          <img
                            class="user-activity-admin__content-thumb"
                            src={contentImageUrl(item.content)!}
                            alt={item.content.title}
                            loading="lazy"
                          />
                        ) : (
                          <div class="user-activity-admin__content-thumb user-activity-admin__content-thumb--placeholder">
                            <CIcon icon="film" size={20} />
                          </div>
                        )}
                        <div class="user-activity-admin__content-info">
                          <span class="user-activity-admin__content-title">{item.content.title}</span>
                          <CBadge variant="muted">{item.content.content_type}</CBadge>
                        </div>
                      </div>
                    )}

                    {item.type === 'billing' && item.metadata && (
                      <div class="user-activity-admin__item-meta">
                        {item.metadata.provider && (
                          <span class="user-activity-admin__meta-tag">
                            Provider: <strong>{item.metadata.provider}</strong>
                          </span>
                        )}
                        {item.metadata.status && (
                          <CBadge variant={item.metadata.status === 'active' ? 'success' : 'muted'}>
                            {item.metadata.status}
                          </CBadge>
                        )}
                        {item.metadata.amount && (
                          <span class="user-activity-admin__meta-tag">
                            {item.metadata.amount} {item.metadata.currency}
                          </span>
                        )}
                      </div>
                    )}

                    {item.type === 'security' && item.metadata && (
                      <div class="user-activity-admin__item-meta">
                        {item.metadata.actor && (
                          <span class="user-activity-admin__meta-tag">
                            By: <strong>{item.metadata.actor}</strong>
                          </span>
                        )}
                        {item.metadata.target_user && item.metadata.target_user !== item.metadata.actor && (
                          <span class="user-activity-admin__meta-tag">
                            Target: <strong>{item.metadata.target_user}</strong>
                          </span>
                        )}
                        {item.metadata.ip_address && (
                          <span class="user-activity-admin__meta-tag user-activity-admin__meta-tag--mono">
                            IP: {item.metadata.ip_address}
                          </span>
                        )}
                        {item.metadata.details && (
                          <span class="user-activity-admin__meta-detail">{item.metadata.details}</span>
                        )}
                      </div>
                    )}

                    {item.type === 'reproduction' && item.metadata?.country_code && (
                      <div class="user-activity-admin__item-meta">
                        <span class="user-activity-admin__meta-tag">
                          Country: <strong>{item.metadata.country_code}</strong>
                        </span>
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>

            {meta.value && meta.value.total_pages > 1 && (
              <div class="user-activity-admin__pagination">
                <CPagination
                  currentPage={meta.value.page}
                  totalPages={meta.value.total_pages}
                  showFirstLast
                  compact
                  onUpdate:currentPage={onPageChange}
                />
              </div>
            )}
          </>
        )}
      </div>
    );
  }
});
