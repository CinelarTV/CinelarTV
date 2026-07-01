import { defineComponent, ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useHead } from 'unhead';
import { ajax } from '../../lib/Ajax';
import CButton from '@/components/forms/c-button';
import CInput from '@/components/forms/c-input.vue';
import CSpinner from '@/components/c-spinner';
import CIcon from '@/components/c-icon.vue';

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

        const statusBadge = () => {
            if (!user.value) return null;
            if (user.value.suspended) {
                return <span class="user-detail-admin__status-badge is-suspended">Suspendido</span>;
            }
            if (user.value.deactivated_at) {
                return <span class="user-detail-admin__status-badge is-deactivated">Desactivado</span>;
            }
            return <span class="user-detail-admin__status-badge is-active">Activo</span>;
        };

        return () => (
            <div class="user-detail-admin">
                <header class="user-detail-admin__hero">
                    <div class="user-detail-admin__hero-top">
                        <button class="user-detail-admin__back" onClick={goBack}>
                            <CIcon icon="arrow-left" size={16} />
                            Volver
                        </button>
                    </div>
                    {loading.value ? (
                        <div />
                    ) : user.value ? (
                        <>
                            <p class="user-detail-admin__eyebrow">Admin Console</p>
                            <h1 class="user-detail-admin__title">{user.value.username}</h1>
                            <p class="user-detail-admin__subtitle">{user.value.email}</p>
                        </>
                    ) : null}
                </header>

                {loading.value ? (
                    <div class="user-detail-admin__card" style="display:flex;justify-content:center;padding:2rem;">
                        <CSpinner />
                    </div>
                ) : user.value ? (
                    <div class="user-detail-admin__layout">
                        <div class="user-detail-admin__card">
                            <h3 class="user-detail-admin__card-title">
                                Información del usuario
                            </h3>
                            <div class="user-detail-admin__info-grid">
                                <div class="user-detail-admin__info-row">
                                    <span class="user-detail-admin__info-label">ID</span>
                                    <span class="user-detail-admin__info-value">{user.value.id}</span>
                                </div>
                                <div class="user-detail-admin__info-row">
                                    <span class="user-detail-admin__info-label">Email</span>
                                    <span class="user-detail-admin__info-value">{user.value.email}</span>
                                </div>
                                <div class="user-detail-admin__info-row">
                                    <span class="user-detail-admin__info-label">Username</span>
                                    <span class="user-detail-admin__info-value">{user.value.username}</span>
                                </div>
                                <div class="user-detail-admin__info-row">
                                    <span class="user-detail-admin__info-label">Estado</span>
                                    <span class="user-detail-admin__info-value">{statusBadge()}</span>
                                </div>
                                <div class="user-detail-admin__info-row">
                                    <span class="user-detail-admin__info-label">Creado</span>
                                    <span class="user-detail-admin__info-value">{formatDate(user.value.created_at)}</span>
                                </div>
                                <div class="user-detail-admin__info-row">
                                    <span class="user-detail-admin__info-label">Actualizado</span>
                                    <span class="user-detail-admin__info-value">{formatDate(user.value.updated_at)}</span>
                                </div>
                                {user.value.suspended && (
                                    <>
                                        <div class="user-detail-admin__info-row">
                                            <span class="user-detail-admin__info-label">Suspendido hasta</span>
                                            <span class="user-detail-admin__info-value">
                                                {formatDate(user.value.suspended_until)}
                                            </span>
                                        </div>
                                        <div class="user-detail-admin__info-row">
                                            <span class="user-detail-admin__info-label">Razón suspensión</span>
                                            <span class="user-detail-admin__info-value">
                                                {user.value.suspended_reason || '-'}
                                            </span>
                                        </div>
                                        <div class="user-detail-admin__info-row">
                                            <span class="user-detail-admin__info-label">Suspendido por</span>
                                            <span class="user-detail-admin__info-value">
                                                {user.value.suspended_by?.username || '-'}
                                            </span>
                                        </div>
                                    </>
                                )}
                                {user.value.deactivated_at && (
                                    <>
                                        <div class="user-detail-admin__info-row">
                                            <span class="user-detail-admin__info-label">Desactivado</span>
                                            <span class="user-detail-admin__info-value">
                                                {formatDate(user.value.deactivated_at)}
                                            </span>
                                        </div>
                                        <div class="user-detail-admin__info-row">
                                            <span class="user-detail-admin__info-label">Razón desactivación</span>
                                            <span class="user-detail-admin__info-value">
                                                {user.value.deactivated_reason || '-'}
                                            </span>
                                        </div>
                                        <div class="user-detail-admin__info-row">
                                            <span class="user-detail-admin__info-label">Desactivado por</span>
                                            <span class="user-detail-admin__info-value">
                                                {user.value.deactivated_by?.username || '-'}
                                            </span>
                                        </div>
                                    </>
                                )}
                            </div>
                        </div>

                        <div class="user-detail-admin__card">
                            <h3 class="user-detail-admin__card-title">
                                Acciones
                            </h3>

                            <div class="user-detail-admin__action-group">
                                <h4 class="user-detail-admin__action-title">Suspender usuario</h4>
                                <div class="user-detail-admin__action-fields">
                                    <label class="user-detail-admin__action-field">
                                        <span>Fecha y hora (opcional)</span>
                                        <input v-model={suspendUntil.value} type="datetime-local" />
                                    </label>
                                    <label class="user-detail-admin__action-field">
                                        <span>Razón</span>
                                        <input v-model={suspendReason.value} placeholder="Motivo de la suspensión" />
                                    </label>
                                </div>
                                <div class="user-detail-admin__action-buttons">
                                    <CButton onClick={suspendUser}>Suspender</CButton>
                                    <CButton onClick={unsuspendUser}>Reanudar</CButton>
                                </div>
                            </div>

                            <div class="user-detail-admin__action-group">
                                <h4 class="user-detail-admin__action-title">Desactivar usuario</h4>
                                <div class="user-detail-admin__action-fields">
                                    <label class="user-detail-admin__action-field">
                                        <span>Razón</span>
                                        <input v-model={deactivateReason.value} placeholder="Motivo de la desactivación" />
                                    </label>
                                </div>
                                <div class="user-detail-admin__action-buttons">
                                    <CButton variant="danger" onClick={deactivateUser}>Desactivar</CButton>
                                    <CButton onClick={activateUser}>Activar</CButton>
                                </div>
                            </div>
                        </div>
                    </div>
                ) : null}
            </div>
        );
    }
});
