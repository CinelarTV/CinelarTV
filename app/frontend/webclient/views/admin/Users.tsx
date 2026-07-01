import { defineComponent, ref, onMounted, watch, nextTick, inject } from 'vue';
import { useHead } from 'unhead';
import { useRouter } from 'vue-router';
import { ajax } from '../../lib/Ajax';
import CInput from "@/components/forms/c-input.vue";
import CButton from '@/components/forms/c-button';
import CSpinner from '@/components/c-spinner';
import CreateUserModal from '../../components/modals/create-user.modal.vue';

interface User {
    id: number;
    email: string;
    username: string;
    role?: string;
    created_at?: string;
    updated_at?: string;
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

        const getUsers = async (reset = false) => {
            if (loading.value || (!hasMore.value && !reset)) return;
            loading.value = true;
            try {
                const params: Record<string, any> = { page: page.value, per_page: perPage };
                if (search.value) params.query = search.value;
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

        const deleteUser = async (id: number) => {
            try {
                await ajax.delete('/admin/users/' + id);
                users.value = users.value.filter(u => u.id !== id);
            } catch (error) {
                console.error(error);
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

        const roleBadgeClass = (role?: string) => {
            if (!role) return 'is-user';
            if (role === 'admin') return 'is-admin';
            if (role === 'moderator') return 'is-moderator';
            return 'is-user';
        };

        const initialLoading = () => loading.value && users.value.length === 0;

        return () => (
            <div class="users-admin">
                <header class="users-admin__hero">
                    <div class="users-admin__hero-header">
                        <div>
                            <p class="users-admin__eyebrow">Admin Console</p>
                            <h1 class="users-admin__title">Gestión de Usuarios</h1>
                            <p class="users-admin__subtitle">
                                Administra cuentas, roles y permisos de la plataforma.
                            </p>
                        </div>
                        {SiteSettings?.allow_admin_to_create_users && (
                            <CButton icon="plus" onClick={openCreate}>
                                Nuevo usuario
                            </CButton>
                        )}
                    </div>
                </header>

                <section class="users-admin__card">
                    <div class="users-admin__section-header">
                        <div>
                            <h2>Usuarios</h2>
                            <p>{users.value.length} {users.value.length === 1 ? 'resultado' : 'resultados'}</p>
                        </div>
                        <div class="users-admin__search">
                            <CInput
                                v-model={search.value}
                                placeholder="Buscar por email o username..."
                            />
                        </div>
                    </div>

                    {initialLoading() ? (
                        <div class="users-admin__loading">
                            <CSpinner />
                        </div>
                    ) : users.value.length === 0 ? (
                        <div class="users-admin__empty">
                            No hay usuarios{search.value ? ' que coincidan con la búsqueda' : '.'}
                        </div>
                    ) : (
                        <div ref={containerRef} class="max-h-[70vh] overflow-y-auto">
                            <table class="w-full text-left admin-table text-sm">
                                <thead class="sticky top-0 z-10">
                                    <tr>
                                        <th>Email</th>
                                        <th>Username</th>
                                        <th>Rol</th>
                                        <th class="text-center">Acciones</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {users.value.map((user) => (
                                        <tr key={user.id}>
                                            <td>{user.email}</td>
                                            <td>
                                                <span
                                                    class="users-admin__username-link"
                                                    onClick={() => router.push(`/admin/users/${user.id}`)}
                                                >
                                                    {user.username}
                                                </span>
                                            </td>
                                            <td>
                                                <span class={`users-admin__role-badge ${roleBadgeClass(user.role)}`}>
                                                    {user.role || 'user'}
                                                </span>
                                            </td>
                                            <td class="text-center">
                                                <CButton
                                                    variant="danger"
                                                    icon="trash2"
                                                    onClick={() => deleteUser(user.id)}
                                                >
                                                    Eliminar
                                                </CButton>
                                            </td>
                                        </tr>
                                    ))}
                                    {loading.value && (
                                        <tr>
                                            <td colSpan={4} class="text-center py-6">
                                                <CSpinner small />
                                            </td>
                                        </tr>
                                    )}
                                </tbody>
                            </table>

                            {!loading.value && !hasMore.value && users.value.length > 0 && (
                                <div class="users-admin__end-marker">
                                    No hay más resultados
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
