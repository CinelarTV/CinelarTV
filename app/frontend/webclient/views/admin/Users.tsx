import { defineComponent, ref, onMounted, watch, nextTick, inject, computed } from 'vue';
import { useHead } from 'unhead';
import { useRouter } from 'vue-router';
import { ajax } from '../../lib/Ajax';
import CInput from "@/components/forms/c-input.vue";
import CButton from '@/components/forms/c-button';
import CIcon from '@/components/c-icon.vue';
import CTable from '@/components/CTable';
import CBadge from '@/components/CBadge';
import CSkeleton from '@/components/CSkeleton';
import CAlert from '@/components/CAlert';
import CreateUserModal from '../../components/modals/create-user.modal.vue';
import type { TableColumn } from '@/components/CTable';

interface User {
    id: number;
    email: string;
    username: string;
    admin: boolean;
    moderator: boolean;
    created_at?: string;
    updated_at?: string;
    suspended?: boolean;
    suspended_until?: string;
    deactivated_at?: string;
    avatar_id?: string;
    profile_name?: string;
}

type SortField = 'created_at' | 'username' | 'email';
type SortDir = 'asc' | 'desc';
type StatusFilter = 'all' | 'active' | 'suspended' | 'deactivated';

const STATUS_OPTIONS: { label: string; value: StatusFilter }[] = [
    { label: 'All users', value: 'all' },
    { label: 'Active', value: 'active' },
    { label: 'Suspended', value: 'suspended' },
    { label: 'Deactivated', value: 'deactivated' }
];

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

function userStatus(user: User): 'active' | 'suspended' | 'deactivated' {
    if (user.suspended) return 'suspended';
    if (user.deactivated_at) return 'deactivated';
    return 'active';
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
    name: 'AdminUsers',
    setup() {
        const users = ref<User[]>([]);
        const loading = ref(false);
        const hasMore = ref(true);
        const page = ref(1);
        const perPage = 30;
        const search = ref('');
        const searchTimeout = ref<number | null>(null);
        const containerRef = ref<HTMLElement | null>(null);
        const router = useRouter();
        const createUserModal = ref<any>(null);
        const SiteSettings = inject<any>('SiteSettings');

        const statusFilter = ref<StatusFilter>('all');
        const sortField = ref<SortField>('created_at');
        const sortDir = ref<SortDir>('desc');
        const showEmails = ref(true);

        const columns = computed<TableColumn[]>(() => {
            const cols: TableColumn[] = [
                { key: 'username', label: 'Username', sortable: true },
            ];
            if (showEmails.value) {
                cols.push({ key: 'email', label: 'Email', sortable: true });
            }
            cols.push({ key: 'status', label: 'Status' });
            cols.push({ key: 'created_at', label: 'Created', sortable: true });
            return cols;
        });

        const tableData = computed(() => {
            return users.value.map(u => ({
                ...u,
                status: userStatus(u)
            }));
        });

        const getUsers = async (reset = false) => {
            if (loading.value || (!hasMore.value && !reset)) return;
            loading.value = true;
            try {
                const params: Record<string, any> = { page: page.value, per_page: perPage };
                if (search.value) params.query = search.value;
                if (statusFilter.value !== 'all') params.status = statusFilter.value;
                params.sort = sortField.value;
                params.dir = sortDir.value;
                const response = await ajax.get('/admin/users.json', { params });
                const newUsers: User[] = response.data.data;
                if (reset) {
                    users.value = newUsers;
                } else {
                    users.value = [...users.value, ...newUsers];
                }
                hasMore.value = newUsers.length === perPage;
            } catch (error) {
                console.error(error);
            } finally {
                loading.value = false;
            }
        };

        const onSearch = () => {
            if (searchTimeout.value) clearTimeout(searchTimeout.value);
            searchTimeout.value = window.setTimeout(() => {
                page.value = 1;
                hasMore.value = true;
                getUsers(true);
            }, 400);
        };

        const onStatusFilter = (status: StatusFilter) => {
            statusFilter.value = status;
            page.value = 1;
            hasMore.value = true;
            getUsers(true);
        };

        const onSort = (key: string) => {
            const field = key as SortField;
            if (sortField.value === field) {
                sortDir.value = sortDir.value === 'asc' ? 'desc' : 'asc';
            } else {
                sortField.value = field;
                sortDir.value = 'asc';
            }
            page.value = 1;
            hasMore.value = true;
            getUsers(true);
        };

        const onScroll = () => {
            const el = containerRef.value;
            if (!el || loading.value || !hasMore.value) return;
            if (el.scrollTop + el.clientHeight >= el.scrollHeight - 100) {
                page.value += 1;
                getUsers();
            }
        };

        onMounted(() => {
            getUsers(true);
            nextTick(() => {
                if (containerRef.value) {
                    containerRef.value.addEventListener('scroll', onScroll);
                }
            });
        });

        watch(search, onSearch);

        useHead({ title: 'Manage Users' });

        const openCreate = () => {
            nextTick(() => createUserModal.value?.setIsOpen(true));
        };

        const handleUserCreated = (user: User) => {
            users.value.unshift(user);
        };

        const initialLoading = () => loading.value && users.value.length === 0;

        return () => (
            <div class="users-admin">
                <header class="users-admin__hero">
                    <div class="users-admin__hero-header">
                        <div>
                            <p class="users-admin__eyebrow">Admin Console</p>
                            <h1 class="users-admin__title">Gestion de Usuarios</h1>
                            <p class="users-admin__subtitle">
                                Administra cuentas, roles y permisos de la plataforma.
                            </p>
                        </div>
                        <div class="users-admin__hero-actions">
                            <CButton
                                variant="ghost"
                                icon={showEmails.value ? 'eye-off' : 'eye'}
                                onClick={() => { showEmails.value = !showEmails.value; }}
                            >
                                {showEmails.value ? 'Hide emails' : 'Show emails'}
                            </CButton>
                            {SiteSettings?.allow_admin_to_create_users && (
                                <CButton icon="plus" onClick={openCreate}>
                                    Nuevo usuario
                                </CButton>
                            )}
                        </div>
                    </div>
                </header>

                <section class="users-admin__card">
                    <div class="users-admin__toolbar">
                        <div class="users-admin__toolbar-left">
                            <div class="users-admin__search">
                                <CIcon icon="search" size={16} />
                                <CInput
                                    class="users-admin__search-input"
                                    v-model={search.value}
                                    placeholder="Search by email or username..."
                                />
                            </div>
                        </div>
                        <div class="users-admin__toolbar-right">
                            <div class="users-admin__filters">
                                {STATUS_OPTIONS.map(opt => (
                                    <button
                                        key={opt.value}
                                        class={`users-admin__filter-btn ${statusFilter.value === opt.value ? 'users-admin__filter-btn--active' : ''}`}
                                        onClick={() => onStatusFilter(opt.value)}
                                    >
                                        {opt.label}
                                    </button>
                                ))}
                            </div>
                        </div>
                    </div>

                    {initialLoading() ? (
                        <CSkeleton variant="avatar-text" count={5} />
                    ) : users.value.length === 0 ? (
                        <CAlert type="info">
                            No hay usuarios{search.value ? ' que coincidan con la busqueda' : '.'}
                        </CAlert>
                    ) : (
                        <div ref={containerRef} class="users-admin__scroll-container">
                            <CTable
                                columns={columns.value}
                                data={tableData.value}
                                sortKey={sortField.value}
                                sortDir={sortDir.value}
                                onSort={onSort}
                                loading={loading.value}
                                emptyText="No users found"
                            >
                                {{
                                    'cell-username': ({ row }: { row: User }) => (
                                        <div class="users-admin__td--user">
                                            <div
                                                class="users-admin__avatar"
                                                style={{ backgroundColor: avatarColor(row.username) }}
                                            >
                                                {row.username.charAt(0).toUpperCase()}
                                            </div>
                                            <div class="users-admin__user-info">
                                                <span
                                                    class="users-admin__username-link"
                                                    onClick={() => router.push(`/admin/users/${row.id}`)}
                                                >
                                                    {row.username}
                                                </span>
                                                <div class="users-admin__user-icons">
                                                    {row.admin && <CIcon icon="shield" size={12} />}
                                                    {row.moderator && <CIcon icon="shield-check" size={12} />}
                                                </div>
                                            </div>
                                        </div>
                                    ),
                                    'cell-status': ({ value }: { value: string }) => (
                                        <CBadge variant={badgeVariant(value)} dot>{value}</CBadge>
                                    ),
                                    'cell-created_at': ({ value }: { value: string }) => (
                                        <span title={value}>{relativeTime(value)}</span>
                                    )
                                }}
                            </CTable>

                            {!loading.value && !hasMore.value && users.value.length > 0 && (
                                <div class="users-admin__end-marker">
                                    No hay mas resultados
                                </div>
                            )}
                        </div>
                    )}
                </section>

                <CreateUserModal ref={createUserModal} onCreated={handleUserCreated} />
            </div>
        );
    }
});
