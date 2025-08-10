import { defineComponent, ref, onMounted, watch, nextTick } from 'vue';
import { useHead } from 'unhead';
import { useRouter } from 'vue-router';
import { ajax } from '../../lib/Ajax';
import CInput from "@/components/forms/c-input.vue";

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
        const dialogRef = ref<HTMLDialogElement | null>(null);

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

        const showCreate = ref(false);
        const createForm = ref({ email: '', username: '', password: '' });
        const createLoading = ref(false);
        const createError = ref<string | null>(null);

        const openCreate = () => {
            showCreate.value = true;
            createForm.value = { email: '', username: '', password: '' };
            createError.value = null;
            nextTick(() => {
                dialogRef.value?.showModal();
            });
        };
        const closeCreate = () => {
            showCreate.value = false;
            createError.value = null;
            dialogRef.value?.close();
        };
        const createUser = async () => {
            createLoading.value = true;
            createError.value = null;
            try {
                const res = await ajax.post('/admin/users/create_user', { user: createForm.value });
                if (res.data?.data?.id) {
                    users.value.unshift(res.data.data);
                    closeCreate();
                } else if (res.data?.data) {
                    createError.value = Object.values(res.data.data).join(', ');
                }
            } catch (e: any) {
                createError.value = e?.response?.data?.error || 'Error al crear usuario';
            } finally {
                createLoading.value = false;
            }
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
                        <button class="btn btn-primary px-4 py-2 rounded font-semibold" onClick={openCreate}>
                            Crear usuario
                        </button>
                    </div>
                </div>
                <div class="panel-body" style="height: 70vh; overflow-y: auto;" ref={containerRef}>
                    <div class="table-responsive rounded-lg overflow-hidden shadow border border-gray-800 bg-[#18181b]">
                        <table class="min-w-full bg-[#18181b] text-sm text-gray-100">
                            <thead class="bg-[#23232a] sticky top-0 z-10">
                                <tr>
                                    <th class="px-6 py-3 text-left font-semibold text-gray-200">Email</th>
                                    <th class="px-6 py-3 text-left font-semibold text-gray-200">Username</th>
                                    <th class="px-6 py-3 text-left font-semibold text-gray-200">Role</th>
                                    <th class="px-6 py-3 text-center font-semibold text-gray-200">Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {users.value.map((user, idx) => (
                                    <tr key={user.id} class={idx % 2 === 0 ? "bg-[#18181b]" : "bg-[#23232a] hover:bg-blue-900/40 transition"}>
                                        <td class="px-6 py-3 whitespace-nowrap text-gray-100">{user.email}</td>
                                        <td class="px-6 py-3 whitespace-nowrap text-gray-100">{user.username}</td>
                                        <td class="px-6 py-3 whitespace-nowrap text-gray-300">{user.role || '-'}</td>
                                        <td class="px-6 py-3 text-center">
                                            <button class="inline-flex items-center gap-2 px-3 py-1.5 rounded bg-red-600 hover:bg-red-700 text-white font-semibold shadow-sm transition text-xs" onClick={() => deleteUser(user.id)}>
                                                <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
                                                Eliminar
                                            </button>
                                        </td>
                                    </tr>
                                ))}
                                {loading.value && (
                                    <tr><td colspan={4} class="text-center py-6 text-gray-400">Cargando...</td></tr>
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
                {showCreate.value && (
                    <dialog ref={dialogRef} class="rounded-lg shadow-lg p-0 w-full max-w-md bg-[#23232a] border border-gray-700" onClose={closeCreate}>
                        <form method="dialog" class="p-8 relative" onSubmit={e => { e.preventDefault(); createUser(); }}>
                            <button type="button" class="absolute top-2 right-2 text-gray-400 hover:text-white" onClick={closeCreate}>
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" /></svg>
                            </button>
                            <h3 class="text-xl font-bold mb-4 text-white">Crear usuario</h3>
                            <div class="mb-4">
                                <label class="block text-gray-300 mb-1">Email</label>
                                <CInput v-model={createForm.value.email} placeholder="Email" class="w-full" />
                            </div>
                            <div class="mb-4">
                                <label class="block text-gray-300 mb-1">Username</label>
                                <CInput v-model={createForm.value.username} placeholder="Username" class="w-full" />
                            </div>
                            <div class="mb-4">
                                <label class="block text-gray-300 mb-1">Contraseña</label>
                                <CInput v-model={createForm.value.password} placeholder="Contraseña" class="w-full" />
                            </div>
                            {createError.value && <div class="text-red-500 mb-2">{createError.value}</div>}
                            <div class="flex gap-2 mt-4">
                                <button type="submit" class="btn btn-primary px-4 py-2 rounded font-semibold" disabled={createLoading.value}>
                                    {createLoading.value ? 'Creando...' : 'Crear'}
                                </button>
                                <button type="button" class="btn btn-secondary px-4 py-2 rounded font-semibold" onClick={closeCreate}>
                                    Cancelar
                                </button>
                            </div>
                        </form>
                    </dialog>
                )}
            </div>
        );
    }
});
