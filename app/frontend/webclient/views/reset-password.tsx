import { defineComponent, ref, computed, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useHead } from 'unhead';
import { ajax } from '@/lib/Ajax';
import { Loader2, KeyRound, CheckCircle } from 'lucide-vue-next';

export default defineComponent({
    name: 'ResetPassword',
    setup() {
        const route = useRoute();
        const router = useRouter();

        const token = ref('');
        const password = ref('');
        const passwordConfirmation = ref('');
        const loading = ref(false);
        const successMessage = ref('');
        const errorMessage = ref('');
        const resolved = ref(false);

        useHead({ title: 'Reset your password' });

        const canSubmit = computed(() =>
            token.value.length > 0
            && password.value.length >= 6
            && password.value === passwordConfirmation.value
            && !loading.value
        );

        onMounted(() => {
            const t = route.query.reset_password_token;
            if (typeof t === 'string' && t.length > 0) {
                token.value = t;
            }
            resolved.value = true;
        });

        const submit = async () => {
            if (!canSubmit.value) return;
            loading.value = true;
            errorMessage.value = '';
            successMessage.value = '';

            try {
                const { data } = await ajax.patch('/users/password.json', {
                    user: {
                        password: password.value,
                        password_confirmation: passwordConfirmation.value,
                        reset_password_token: token.value,
                    },
                }, {
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                    },
                });

                successMessage.value = data?.message || 'Your password has been reset successfully.';
                password.value = '';
                passwordConfirmation.value = '';

                setTimeout(() => {
                    router.push({ name: 'home.index' });
                }, 2500);
            } catch (error: any) {
                const data = error?.response?.data;
                errorMessage.value =
                    data?.errors?.[0]
                    || data?.error
                    || data?.message
                    || 'Could not reset password. The link may have expired.';
            } finally {
                loading.value = false;
            }
        };

        return () => (
            <div class="min-h-screen bg-[var(--c-primary-color)] text-[var(--c-body-text-color)]">
                <div class="mx-auto flex min-h-screen w-full max-w-md items-center px-4 py-8">
                    <div class="w-full rounded-2xl border border-[var(--c-primary-400)] bg-[var(--c-primary-600)] p-6 shadow-xl">

                        {!resolved.value ? null : !token.value ? (
                            <div class="text-center">
                                <div class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-rose-500/10">
                                    <KeyRound size={22} class="text-rose-400" />
                                </div>
                                <h1 class="text-xl font-semibold">Invalid link</h1>
                                <p class="mt-2 text-sm text-[var(--c-primary-100)]">
                                    This password reset link is invalid or has expired. Please request a new one.
                                </p>
                                <a
                                    href="/forgot-password"
                                    class="mt-6 inline-flex items-center gap-2 rounded-xl bg-[var(--c-tertiary-color)] px-5 py-2.5 text-sm font-semibold text-white transition-all hover:bg-[var(--c-tertiary-100)]"
                                >
                                    Request new link
                                </a>
                            </div>
                        ) : successMessage.value ? (
                            <div class="text-center">
                                <div class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-emerald-500/10">
                                    <CheckCircle size={22} class="text-emerald-400" />
                                </div>
                                <h1 class="text-xl font-semibold">Password reset</h1>
                                <p class="mt-2 text-sm text-emerald-400">
                                    {successMessage.value}
                                </p>
                                <p class="mt-1 text-xs text-[var(--c-primary-100)]">
                                    Redirecting you shortly...
                                </p>
                            </div>
                        ) : (
                            <>
                                <div class="mb-6 text-center">
                                    <div class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-[var(--c-tertiary-color)]/10">
                                        <KeyRound size={22} class="text-[var(--c-tertiary-color)]" />
                                    </div>
                                    <h1 class="text-xl font-semibold">Set new password</h1>
                                    <p class="mt-1 text-sm text-[var(--c-primary-100)]">
                                        Choose a strong password for your account
                                    </p>
                                </div>

                                <form onSubmit={(e) => { e.preventDefault(); submit(); }} novalidate>
                                    <div class="space-y-4">
                                        <div>
                                            <label
                                                for="reset-password-input"
                                                class="mb-1.5 block text-xs font-medium uppercase tracking-widest text-[var(--c-body-text-color)]"
                                            >
                                                New password
                                            </label>
                                            <input
                                                type="password"
                                                value={password.value}
                                                onInput={(e: any) => (password.value = e.target.value)}
                                                id="reset-password-input"
                                                placeholder="At least 6 characters"
                                                class="c-input"
                                                required
                                                autofocus
                                            />
                                        </div>

                                        <div>
                                            <label
                                                for="reset-password-confirm-input"
                                                class="mb-1.5 block text-xs font-medium uppercase tracking-widest text-[var(--c-body-text-color)]"
                                            >
                                                Confirm password
                                            </label>
                                            <input
                                                type="password"
                                                value={passwordConfirmation.value}
                                                onInput={(e: any) => (passwordConfirmation.value = e.target.value)}
                                                id="reset-password-confirm-input"
                                                placeholder="Repeat your password"
                                                class="c-input"
                                                required
                                            />
                                        </div>
                                    </div>

                                    {password.value.length > 0 && password.value !== passwordConfirmation.value && (
                                        <p class="mt-2 text-xs text-rose-400">Passwords don't match</p>
                                    )}

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
                                                : <KeyRound size={15} />
                                            }
                                            Reset password
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
