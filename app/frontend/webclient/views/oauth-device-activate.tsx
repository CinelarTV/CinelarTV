import { defineComponent, ref, computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useHead } from 'unhead';
import { ajax } from '@/lib/Ajax';
import { Loader2, Monitor, CheckCircle, AlertTriangle } from 'lucide-vue-next';

export default defineComponent({
    name: 'OauthDeviceActivate',
    setup() {
        const route = useRoute();
        const userCode = ref('');
        const loading = ref(false);
        const successMessage = ref('');
        const errorMessage = ref('');

        useHead({ title: 'Activar dispositivo' });

        const canSubmit = computed(() => userCode.value.trim().length > 0 && !loading.value);

        const submit = async () => {
            if (!canSubmit.value) return;
            loading.value = true;
            errorMessage.value = '';
            successMessage.value = '';

            try {
                const { data } = await ajax.post('/oauth/device.json', {
                    user_code: userCode.value.trim().toUpperCase(),
                });
                successMessage.value = data?.message || 'Dispositivo vinculado correctamente.';
            } catch (error: any) {
                const data = error?.response?.data;
                errorMessage.value =
                    data?.errors?.[0]
                    || data?.error
                    || 'No se pudo validar el codigo.';
            } finally {
                loading.value = false;
            }
        };

        onMounted(() => {
            const code = route.query.user_code;
            if (typeof code === 'string' && code.length > 0) {
                userCode.value = code.toUpperCase();
            }
        });

        return () => (
            <div class="text-[var(--c-body-text-color)]">
                <div class="mx-auto flex w-full max-w-md items-center px-4 py-8">
                    <div class="w-full rounded-2xl border border-[var(--c-primary-400)] bg-[var(--c-primary-600)] p-6 shadow-xl">

                        {successMessage.value ? (
                            <div class="text-center">
                                <div class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-emerald-500/10">
                                    <CheckCircle size={22} class="text-emerald-400" />
                                </div>
                                <h1 class="text-xl font-semibold">Dispositivo activado</h1>
                                <p class="mt-2 text-sm text-emerald-400 leading-relaxed">
                                    {successMessage.value}
                                </p>
                                <p class="mt-1 text-xs text-[var(--c-primary-100)]">
                                    Ya puedes cerrar esta ventana y volver a la TV.
                                </p>
                            </div>
                        ) : (
                            <>
                                <div class="mb-6 text-center">
                                    <div class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-[var(--c-tertiary-color)]/10">
                                        <Monitor size={22} class="text-[var(--c-tertiary-color)]" />
                                    </div>
                                    <h1 class="text-xl font-semibold">Activar dispositivo</h1>
                                    <p class="mt-1 text-sm text-[var(--c-primary-100)]">
                                        Ingresa el codigo que aparece en tu TV o dispositivo.
                                    </p>
                                </div>

                                <form onSubmit={(e) => { e.preventDefault(); submit(); }} novalidate>
                                    <div>
                                        <label
                                            for="oauth-device-code-input"
                                            class="mb-1.5 block text-xs font-medium uppercase tracking-widest text-[var(--c-body-text-color)]"
                                        >
                                            Codigo de usuario
                                        </label>
                                        <input
                                            id="oauth-device-code-input"
                                            type="text"
                                            value={userCode.value}
                                            onInput={(e: any) => {
                                                userCode.value = e.target.value.toUpperCase();
                                                errorMessage.value = '';
                                            }}
                                            placeholder="ABCD-EFGH"
                                            class="c-input"
                                            required
                                            autofocus
                                        />
                                    </div>

                                    {errorMessage.value && (
                                        <p class="mt-3 text-xs font-medium text-rose-400">
                                            {errorMessage.value}
                                        </p>
                                    )}

                                    <div class="mt-6">
                                        <button
                                            type="submit"
                                            disabled={!canSubmit.value}
                                            class="inline-flex w-full items-center justify-center gap-2 rounded-xl bg-[var(--c-tertiary-color)] px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-all hover:bg-[var(--c-tertiary-100)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--c-tertiary-color)] disabled:cursor-not-allowed disabled:opacity-40"
                                        >
                                            {loading.value
                                                ? <Loader2 size={15} class="animate-spin" />
                                                : <Monitor size={15} />
                                            }
                                            Vincular dispositivo
                                        </button>
                                    </div>
                                </form>
                            </>
                        )}

                    </div>
                </div>
            </div>
        );
    }
});
