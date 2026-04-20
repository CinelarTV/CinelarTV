import { defineComponent, ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useHead } from 'unhead';
import { ajax } from '../../lib/Ajax';
import CButton from '@/components/forms/c-button';
import CInput from '@/components/forms/c-input.vue';

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

export default defineComponent({
    name: 'AdminUserDetail',
    setup() {
        const route = useRoute();
        const router = useRouter();
        const id = route.params.id as string;
        const user = ref<any>(null);
        const loading = ref(false);
        const suspendUntil = ref('');
        const suspendReason = ref('');
        const deactivateReason = ref('');

        const fetchUser = async () => {
            loading.value = true;
            try {
                const res = await ajax.get(`/admin/users/${id}.json`);
                user.value = res.data.data;
                suspendUntil.value = toLocalDatetimeInput(user.value.suspended_until);
            } catch (e) {
                console.error(e);
            } finally {
                loading.value = false;
            }
        };

        const goBack = () => router.push('/admin/users');

        const suspendUser = async () => {
            try {
                const payload: any = { reason: suspendReason.value };
                if (suspendUntil.value) payload.until = new Date(suspendUntil.value).toISOString();
                await ajax.post(`/admin/users/${id}/suspend`, payload);
                await fetchUser();
            } catch (e) {
                console.error(e);
            }
        };

        const unsuspendUser = async () => {
            try {
                await ajax.post(`/admin/users/${id}/unsuspend`);
                await fetchUser();
            } catch (e) {
                console.error(e);
            }
        };

        const deactivateUser = async () => {
            try {
                await ajax.post(`/admin/users/${id}/deactivate`, { reason: deactivateReason.value });
                await fetchUser();
            } catch (e) {
                console.error(e);
            }
        };

        const activateUser = async () => {
            try {
                await ajax.post(`/admin/users/${id}/activate`);
                await fetchUser();
            } catch (e) {
                console.error(e);
            }
        };

        onMounted(fetchUser);

        useHead({ title: `Usuario ${id}` });

        return () => (
            <div class="panel">
                <div class="panel-header flex items-center justify-between">
                    <h2 class="panel-title">Detalle de usuario</h2>
                    <div>
                        <CButton onClick={goBack}>Volver</CButton>
                    </div>
                </div>
                <div class="panel-body">
                    {loading.value && <div>Cargando...</div>}
                    {!loading.value && user.value && (
                        <div class="grid grid-cols-2 gap-6">
                            <div>
                                <h3 class="text-lg font-semibold">Información</h3>
                                <table class="mt-2 w-full text-sm">
                                    <tbody>
                                        <tr><td class="font-semibold">ID</td><td>{user.value.id}</td></tr>
                                        <tr><td class="font-semibold">Email</td><td>{user.value.email}</td></tr>
                                        <tr><td class="font-semibold">Username</td><td>{user.value.username}</td></tr>
                                        <tr><td class="font-semibold">Creado</td><td>{user.value.created_at}</td></tr>
                                        <tr><td class="font-semibold">Actualizado</td><td>{user.value.updated_at}</td></tr>
                                        <tr><td class="font-semibold">Suspendido</td><td>{user.value.suspended ? 'Sí' : 'No'}</td></tr>
                                        <tr><td class="font-semibold">Suspendido hasta</td><td>{user.value.suspended_until || '-'}</td></tr>
                                        <tr><td class="font-semibold">Razón suspensión</td><td>{user.value.suspended_reason || '-'}</td></tr>
                                        <tr><td class="font-semibold">Suspendido por</td><td>{user.value.suspended_by ? user.value.suspended_by.username : '-'}</td></tr>
                                        <tr><td class="font-semibold">Desactivado</td><td>{user.value.deactivated_at ? 'Sí' : 'No'}</td></tr>
                                        <tr><td class="font-semibold">Razón desactivación</td><td>{user.value.deactivated_reason || '-'}</td></tr>
                                        <tr><td class="font-semibold">Desactivado por</td><td>{user.value.deactivated_by ? user.value.deactivated_by.username : '-'}</td></tr>
                                    </tbody>
                                </table>
                            </div>

                            <div>
                                <h3 class="text-lg font-semibold">Acciones</h3>
                                <div class="mt-3 space-y-4">
                                    <div class="p-4 border rounded">
                                        <div class="mb-2 font-semibold">Suspender usuario</div>
                                        <CInput v-model={suspendUntil.value} type="datetime-local" placeholder="Fecha y hora (opcional)" />
                                        <CInput v-model={suspendReason.value} placeholder="Razón" />
                                        <div class="mt-2 flex gap-2">
                                            <CButton onClick={suspendUser}>Suspender</CButton>
                                            <CButton onClick={unsuspendUser} variant="secondary">Reanudar</CButton>
                                        </div>
                                    </div>

                                    <div class="p-4 border rounded">
                                        <div class="mb-2 font-semibold">Desactivar usuario</div>
                                        <CInput v-model={deactivateReason.value} placeholder="Razón" />
                                        <div class="mt-2 flex gap-2">
                                            <CButton onClick={deactivateUser} variant="danger">Desactivar</CButton>
                                            <CButton onClick={activateUser} variant="secondary">Activar</CButton>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    )}
                </div>
            </div>
        );
    }
});
