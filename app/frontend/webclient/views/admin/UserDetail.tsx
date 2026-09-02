import { defineComponent, ref, onMounted, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useHead } from 'unhead';
import { ajax } from '../../lib/Ajax';
import CButton from '@/components/forms/c-button';
import CInput from '@/components/forms/c-input.vue';
import CIcon from '@/components/c-icon.vue';
import CBadge from '@/components/CBadge';
import CAlert from '@/components/CAlert';
import CSkeleton from '@/components/CSkeleton';
import type { StatCardItem } from '@/components/CStatCard';

interface UserData {
    id: number;
    email: string;
    username: string;
    admin: boolean;
    moderator: boolean;
    created_at?: string;
    updated_at?: string;
    suspended?: boolean;
    suspended_until?: string;
    suspended_reason?: string;
    suspended_by?: { id: number; username: string; email: string };
    deactivated_at?: string;
    deactivated_reason?: string;
    deactivated_by?: { id: number; username: string; email: string };
    avatar_id?: string;
    profile_name?: string;
}

function toLocalDatetimeInput(value?: string | null) {
    if (!value) return '';
    const d = new Date(value);
    if (Number.isNaN(d.getTime())) return '';
    const pad = (n: number) => n.toString().padStart(2, '0');
    const YYYY = d.getFullYear();
    const MM = pad(d.getMonth() + 1);
    const DD = pad(d.getDate());
    const hh = pad(d.getHours());
    const mm = pad(d.getMinutes());
    return `${YYYY}-${MM}-${DD}T${hh}:${mm}`;
}

function formatDate(value?: string | null) {
    if (!value) return '-';
    const d = new Date(value);
    if (Number.isNaN(d.getTime())) return '-';
    return d.toLocaleString();
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

const AVATAR_COLORS = [
    '#6366f1', '#8b5cf6', '#a855f7', '#ec4899', '#ef4444',
    '#f97316', '#eab308', '#22c55e', '#14b8a6', '#06b6d4',
    '#3b82f6', '#6366f1'
];

function avatarColor(username: string): string {
    let hash = 0;
    for (let i = 0; i < username.length; i++) {
        hash = username.charCodeAt(i) + ((hash << 5) - hash);
    }
    return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length];
}

function badgeVariant(status: string): 'success' | 'warning' | 'danger' | 'muted' {
    if (status === 'active') return 'success';
    if (status === 'suspended') return 'warning';
    if (status === 'deactivated') return 'danger';
    return 'muted';
}

export default defineComponent({
    name: 'AdminUserDetail',
    setup() {
        const route = useRoute();
        const router = useRouter();
        const id = route.params.id as string;
        const user = ref<UserData | null>(null);
        const loading = ref(false);
        const suspendUntil = ref('');
        const suspendReason = ref('');
        const deactivateReason = ref('');
        const actionLoading = ref<string | null>(null);

        const fetchUser = async () => {
            loading.value = true;
            try {
                const res = await ajax.get(`/admin/users/${id}.json`);
                user.value = res.data.data;
                suspendUntil.value = toLocalDatetimeInput(user.value?.suspended_until);
            } catch (e) {
                console.error(e);
            } finally {
                loading.value = false;
            }
        };

        const goBack = () => router.push('/admin/users');

        const runAction = async (name: string, fn: () => Promise<void>) => {
            actionLoading.value = name;
            try {
                await fn();
                await fetchUser();
            } catch (e) {
                console.error(e);
            } finally {
                actionLoading.value = null;
            }
        };

        const suspendUser = () => runAction('suspend', async () => {
            const payload: any = { reason: suspendReason.value };
            if (suspendUntil.value) payload.until = new Date(suspendUntil.value).toISOString();
            await ajax.post(`/admin/users/${id}/suspend`, payload);
            suspendReason.value = '';
            suspendUntil.value = '';
        });

        const unsuspendUser = () => runAction('unsuspend', () =>
            ajax.post(`/admin/users/${id}/unsuspend`)
        );

        const deactivateUser = () => runAction('deactivate', async () => {
            await ajax.post(`/admin/users/${id}/deactivate`, { reason: deactivateReason.value });
            deactivateReason.value = '';
        });

        const activateUser = () => runAction('activate', () =>
            ajax.post(`/admin/users/${id}/activate`)
        );

        const deleteUser = async (userId: number) => {
            if (!confirm('Are you sure you want to delete this user? This cannot be undone.')) return;
            try {
                await ajax.delete(`/admin/users/${userId}`);
                router.push('/admin/users');
            } catch (e) {
                console.error(e);
            }
        };

        onMounted(fetchUser);

        useHead({ title: computed(() => user.value ? `${user.value.username} - User` : 'User') });

        const status = computed(() => {
            if (!user.value) return 'active';
            if (user.value.suspended) return 'suspended';
            if (user.value.deactivated_at) return 'deactivated';
            return 'active';
        });

        const userStats = computed<StatCardItem[]>(() => {
            if (!user.value) return [];
            return [
                { label: 'ID', value: user.value.id, icon: 'hash', accent: 'primary' },
                { label: 'Status', value: status.value, icon: 'activity', accent: badgeVariant(status.value) as any },
                { label: 'Role', value: user.value.admin ? 'Admin' : user.value.moderator ? 'Moderator' : 'User', icon: 'shield' },
            ];
        });

        return () => (
            <div class="user-detail-admin">
                <header class="user-detail-admin__hero">
                    <div class="user-detail-admin__hero-top">
                        <button class="user-detail-admin__back" onClick={goBack}>
                            <CIcon icon="arrow-left" size={16} />
                            Users
                        </button>
                    </div>

                    {loading.value ? (
                        <div class="user-detail-admin__loading">
                            <CSkeleton variant="avatar-text" count={2} />
                        </div>
                    ) : user.value ? (
                        <div class="user-detail-admin__hero-profile">
                            <div
                                class="user-detail-admin__avatar"
                                style={{ backgroundColor: avatarColor(user.value.username) }}
                            >
                                {user.value.username.charAt(0).toUpperCase()}
                            </div>
                            <div class="user-detail-admin__hero-info">
                                <div class="user-detail-admin__hero-name-row">
                                    <h1 class="user-detail-admin__title">{user.value.username}</h1>
                                    <CBadge variant={badgeVariant(status.value)} dot>{status.value}</CBadge>
                                    {user.value.admin && (
                                        <CBadge variant="primary" icon="shield">Admin</CBadge>
                                    )}
                                    {user.value.moderator && (
                                        <CBadge variant="accent" icon="shield-check">Moderator</CBadge>
                                    )}
                                </div>
                                <p class="user-detail-admin__subtitle">{user.value.email}</p>
                            </div>
                            <div class="user-detail-admin__hero-actions">
                                {user.value.suspended ? (
                                    <CButton
                                        variant="primary"
                                        icon="play"
                                        loading={actionLoading.value === 'unsuspend'}
                                        onClick={unsuspendUser}
                                    >
                                        Unsuspend
                                    </CButton>
                                ) : user.value.deactivated_at ? (
                                    <CButton
                                        variant="primary"
                                        icon="check"
                                        loading={actionLoading.value === 'activate'}
                                        onClick={activateUser}
                                    >
                                        Activate
                                    </CButton>
                                ) : null}
                            </div>
                        </div>
                    ) : null}
                </header>

                {loading.value ? (
                    <div class="user-detail-admin__loading">
                        <CSkeleton variant="avatar-text" count={4} />
                    </div>
                ) : user.value ? (
                    <div class="user-detail-admin__layout">
                        <div class="user-detail-admin__main">
                            <section class="user-detail-admin__section">
                                <h2 class="user-detail-admin__section-title">
                                    <CIcon icon="user" size={18} />
                                    User Details
                                </h2>
                                <div class="user-detail-admin__details-grid">
                                    <div class="user-detail-admin__detail">
                                        <span class="user-detail-admin__detail-label">ID</span>
                                        <span class="user-detail-admin__detail-value user-detail-admin__detail-value--mono">{user.value.id}</span>
                                    </div>
                                    <div class="user-detail-admin__detail">
                                        <span class="user-detail-admin__detail-label">Username</span>
                                        <span class="user-detail-admin__detail-value">{user.value.username}</span>
                                    </div>
                                    <div class="user-detail-admin__detail">
                                        <span class="user-detail-admin__detail-label">Email</span>
                                        <span class="user-detail-admin__detail-value">{user.value.email}</span>
                                    </div>
                                    <div class="user-detail-admin__detail">
                                        <span class="user-detail-admin__detail-label">Profile Name</span>
                                        <span class="user-detail-admin__detail-value">{user.value.profile_name || '-'}</span>
                                    </div>
                                    <div class="user-detail-admin__detail">
                                        <span class="user-detail-admin__detail-label">Status</span>
                                        <span class="user-detail-admin__detail-value">
                                            <CBadge variant={badgeVariant(status.value)}>{status.value}</CBadge>
                                        </span>
                                    </div>
                                </div>
                            </section>

                            <section class="user-detail-admin__section">
                                <h2 class="user-detail-admin__section-title">
                                    <CIcon icon="shield" size={18} />
                                    Permissions
                                </h2>
                                <div class="user-detail-admin__details-grid">
                                    <div class="user-detail-admin__detail">
                                        <span class="user-detail-admin__detail-label">Admin</span>
                                        <span class="user-detail-admin__detail-value">
                                            <CBadge variant={user.value.admin ? 'success' : 'muted'} icon={user.value.admin ? 'check' : 'x'}>
                                                {user.value.admin ? 'Yes' : 'No'}
                                            </CBadge>
                                        </span>
                                    </div>
                                    <div class="user-detail-admin__detail">
                                        <span class="user-detail-admin__detail-label">Moderator</span>
                                        <span class="user-detail-admin__detail-value">
                                            <CBadge variant={user.value.moderator ? 'success' : 'muted'} icon={user.value.moderator ? 'check' : 'x'}>
                                                {user.value.moderator ? 'Yes' : 'No'}
                                            </CBadge>
                                        </span>
                                    </div>
                                </div>
                            </section>

                            <section class="user-detail-admin__section">
                                <h2 class="user-detail-admin__section-title">
                                    <CIcon icon="clock" size={18} />
                                    Activity
                                </h2>
                                <div class="user-detail-admin__details-grid">
                                    <div class="user-detail-admin__detail">
                                        <span class="user-detail-admin__detail-label">Created</span>
                                        <span class="user-detail-admin__detail-value">
                                            <span title={user.value.created_at}>{relativeTime(user.value.created_at)}</span>
                                        </span>
                                    </div>
                                    <div class="user-detail-admin__detail">
                                        <span class="user-detail-admin__detail-label">Last Updated</span>
                                        <span class="user-detail-admin__detail-value">
                                            <span title={user.value.updated_at}>{relativeTime(user.value.updated_at)}</span>
                                        </span>
                                    </div>
                                </div>
                            </section>

                            {(user.value.suspended || user.value.deactivated_at) && (
                                <section class="user-detail-admin__section">
                                    <h2 class="user-detail-admin__section-title">
                                        <CIcon icon="alert-triangle" size={18} />
                                        Status Details
                                    </h2>
                                    <div class="user-detail-admin__details-grid">
                                        {user.value.suspended && (
                                            <>
                                                <div class="user-detail-admin__detail">
                                                    <span class="user-detail-admin__detail-label">Suspended Until</span>
                                                    <span class="user-detail-admin__detail-value">{formatDate(user.value.suspended_until)}</span>
                                                </div>
                                                <div class="user-detail-admin__detail">
                                                    <span class="user-detail-admin__detail-label">Suspension Reason</span>
                                                    <span class="user-detail-admin__detail-value">{user.value.suspended_reason || '-'}</span>
                                                </div>
                                                <div class="user-detail-admin__detail">
                                                    <span class="user-detail-admin__detail-label">Suspended By</span>
                                                    <span class="user-detail-admin__detail-value">{user.value.suspended_by?.username || '-'}</span>
                                                </div>
                                            </>
                                        )}
                                        {user.value.deactivated_at && (
                                            <>
                                                <div class="user-detail-admin__detail">
                                                    <span class="user-detail-admin__detail-label">Deactivated At</span>
                                                    <span class="user-detail-admin__detail-value">{formatDate(user.value.deactivated_at)}</span>
                                                </div>
                                                <div class="user-detail-admin__detail">
                                                    <span class="user-detail-admin__detail-label">Deactivation Reason</span>
                                                    <span class="user-detail-admin__detail-value">{user.value.deactivated_reason || '-'}</span>
                                                </div>
                                                <div class="user-detail-admin__detail">
                                                    <span class="user-detail-admin__detail-label">Deactivated By</span>
                                                    <span class="user-detail-admin__detail-value">{user.value.deactivated_by?.username || '-'}</span>
                                                </div>
                                            </>
                                        )}
                                    </div>
                                </section>
                            )}
                        </div>

                        <aside class="user-detail-admin__sidebar">
                            <section class="user-detail-admin__section">
                                <h2 class="user-detail-admin__section-title">
                                    <CIcon icon="settings" size={18} />
                                    Actions
                                </h2>
                                <div class="user-detail-admin__actions-list">
                                    {!user.value.suspended && !user.value.deactivated_at && (
                                        <>
                                            <div class="user-detail-admin__action-block">
                                                <h4 class="user-detail-admin__action-label">Suspend User</h4>
                                                <label class="user-detail-admin__action-field">
                                                    <span>Until (optional)</span>
                                                    <input v-model={suspendUntil.value} type="datetime-local" />
                                                </label>
                                                <label class="user-detail-admin__action-field">
                                                    <span>Reason</span>
                                                    <input v-model={suspendReason.value} placeholder="Reason for suspension" />
                                                </label>
                                                <CButton
                                                    variant="danger"
                                                    icon="ban"
                                                    loading={actionLoading.value === 'suspend'}
                                                    onClick={suspendUser}
                                                    style={{ width: '100%' }}
                                                >
                                                    Suspend
                                                </CButton>
                                            </div>

                                            <div class="user-detail-admin__action-block">
                                                <h4 class="user-detail-admin__action-label">Deactivate User</h4>
                                                <label class="user-detail-admin__action-field">
                                                    <span>Reason</span>
                                                    <input v-model={deactivateReason.value} placeholder="Reason for deactivation" />
                                                </label>
                                                <CButton
                                                    variant="danger"
                                                    icon="x-circle"
                                                    loading={actionLoading.value === 'deactivate'}
                                                    onClick={deactivateUser}
                                                    style={{ width: '100%' }}
                                                >
                                                    Deactivate
                                                </CButton>
                                            </div>
                                        </>
                                    )}

                                    {user.value.suspended && (
                                        <div class="user-detail-admin__action-block">
                                            <CButton
                                                variant="primary"
                                                icon="play"
                                                loading={actionLoading.value === 'unsuspend'}
                                                onClick={unsuspendUser}
                                                style={{ width: '100%' }}
                                            >
                                                Unsuspend User
                                            </CButton>
                                        </div>
                                    )}

                                    {user.value.deactivated_at && (
                                        <div class="user-detail-admin__action-block">
                                            <CButton
                                                variant="primary"
                                                icon="check"
                                                loading={actionLoading.value === 'activate'}
                                                onClick={activateUser}
                                                style={{ width: '100%' }}
                                            >
                                                Activate User
                                            </CButton>
                                        </div>
                                    )}
                                </div>
                            </section>

                            <section class="user-detail-admin__section user-detail-admin__section--danger">
                                <h2 class="user-detail-admin__section-title">
                                    <CIcon icon="alert-triangle" size={18} />
                                    Danger Zone
                                </h2>
                                <div class="user-detail-admin__actions-list">
                                    <div class="user-detail-admin__action-block">
                                        <CAlert type="danger">
                                            Permanently delete this user and all associated data. This action cannot be undone.
                                        </CAlert>
                                        <CButton
                                            variant="danger"
                                            icon="trash"
                                            onClick={() => deleteUser(user.value!.id)}
                                            style={{ width: '100%' }}
                                        >
                                            Delete User
                                        </CButton>
                                    </div>
                                </div>
                            </section>
                        </aside>
                    </div>
                ) : null}
            </div>
        );
    }
});
