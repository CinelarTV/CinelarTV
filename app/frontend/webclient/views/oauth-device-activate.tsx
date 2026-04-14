import { defineComponent, ref, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useHead } from 'unhead';
import { ajax } from '@/lib/Ajax';

export default defineComponent({
    name: 'OauthDeviceActivate',
    setup() {
        const route = useRoute();
        const userCode = ref('');
        const loading = ref(false);
        const successMessage = ref('');
        const errorMessage = ref('');

        useHead({ title: 'Activar dispositivo' });

        const submit = async () => {
            errorMessage.value = '';
            successMessage.value = '';
            const normalized = userCode.value.trim().toUpperCase();

            if (!normalized) {
                errorMessage.value = 'Ingresa un codigo valido.';
                return;
            }

            loading.value = true;
            try {
                const { data } = await ajax.post('/oauth/device.json', { user_code: normalized });
                successMessage.value = data?.message || 'Dispositivo vinculado correctamente.';
            } catch (error: any) {
                errorMessage.value = error?.response?.data?.errors?.[0] || 'No se pudo validar el codigo.';
            } finally {
                loading.value = false;
            }
        };

        onMounted(() => {
            const code = route.query.user_code;
            if (typeof code === 'string') {
                userCode.value = code;
            }
        });

        return () => (
            <div class="min-h-screen bg-[#0b0d12] text-white">
                <div class="mx-auto flex min-h-screen w-full max-w-md items-center px-4 py-8">
                    <div class="w-full rounded-2xl border border-white/10 bg-white/5 p-6 shadow-xl backdrop-blur">
                        <p class="mb-2 text-xs uppercase tracking-wider text-white/60">OAuth Device Flow</p>
                        <h1 class="mb-1 text-2xl font-semibold">Activar dispositivo</h1>
                        <p class="mb-6 text-sm text-white/70">Ingresa el codigo que aparece en tu TV o dispositivo.</p>

                        <label class="mb-2 block text-sm text-white/80">Codigo de usuario</label>
                        <input
                            value={userCode.value}
                            onInput={(event: Event) => {
                                const target = event.target as HTMLInputElement;
                                userCode.value = target.value;
                            }}
                            placeholder="ABCD-EFGH"
                            class="mb-4 w-full rounded-lg border border-white/15 bg-black/30 px-3 py-2 text-base uppercase text-white placeholder:text-white/35 outline-none transition focus:border-white/40"
                        />

                        <button
                            type="button"
                            disabled={loading.value}
                            onClick={submit}
                            class="inline-flex w-full items-center justify-center rounded-lg bg-red-600 px-4 py-2.5 font-semibold text-white transition hover:bg-red-500 disabled:cursor-not-allowed disabled:opacity-60"
                        >
                            {loading.value ? 'Validando...' : 'Vincular dispositivo'}
                        </button>

                        {successMessage.value && (
                            <p class="mt-4 rounded-lg border border-emerald-400/30 bg-emerald-500/10 px-3 py-2 text-sm text-emerald-200">
                                {successMessage.value}
                            </p>
                        )}

                        {errorMessage.value && (
                            <p class="mt-4 rounded-lg border border-red-400/30 bg-red-500/10 px-3 py-2 text-sm text-red-200">
                                {errorMessage.value}
                            </p>
                        )}
                    </div>
                </div>
            </div>
        );
    }
});
