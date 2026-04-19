import { defineComponent, ref, onMounted, watch, nextTick, inject } from 'vue';
import { useHead } from 'unhead';
import { useRouter } from 'vue-router';
import { ajax } from '../../lib/Ajax';
import CInput from "@/components/forms/c-input.vue";
import CButton from '@/components/forms/c-button';
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

        return () => (
            <div class="panel manage-users">
                <div class="panel-header">
                    <h2 class="panel-title">Usuarios</h2>
                    <div class="mb-4 max-w-xs flex gap-2 items-center">
                        <CInput
                            v-model={search.value}
                            placeholder="Buscar usuario por email o username..."
                            class="w-full"
                        />
                        {SiteSettings?.allow_admin_to_create_users && (
                            <CButton icon="plus" onClick={openCreate}>Crear usuario</CButton>
                        )}
                    </div>
                </div>
                <div class="panel-body max-h-[70vh] overflow-y-auto" ref={containerRef}>
                    <div class="overflow-x-auto">
                        <table class="w-full text-left admin-table text-sm">
                            <thead class="sticky top-0 z-10">
                                <tr>
                                    <th>Email</th>
                                    <th>Username</th>
                                    <th>Role</th>
                                    <th class="text-center">Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {users.value.map((user) => (
                                    <tr key={user.id}>
                                        <td>{user.email}</td>
                                        <td>
                                            <a class="text-blue-600 hover:underline cursor-pointer" onClick={() => router.push(`/admin/users/${user.id}`)}>{user.username}</a>
                                        </td>
                                        <td>{user.role || '-'}</td>
                                        <td class="text-center">
                                            <CButton type="danger" icon="trash2" onClick={() => deleteUser(user.id)}>Eliminar</CButton>
                                        </td>
                                    </tr>
                                ))}
                                {loading.value && (
                                    <tr><td colSpan={4} class="text-center py-6 text-gray-400">Cargando...</td></tr>
                                )}
                            </tbody>
                        </table>

                        {!loading.value && users.value.length === 0 && (
                            <div class="text-center py-8 text-gray-500">No hay usuarios.</div>
                        )}
                        {!loading.value && !hasMore.value && users.value.length > 0 && (
                            <div class="text-center py-4 text-gray-500">No hay más resultados.</div>
                        )}
                    </div>
                </div>
                <CreateUserModal ref={createUserModal} onCreated={handleUserCreated} />
            </div>
        );
    }
});
