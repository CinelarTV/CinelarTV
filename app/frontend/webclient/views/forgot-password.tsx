import { defineComponent, ref, computed } from 'vue';
import { useHead } from 'unhead';
import { ajax } from '@/lib/Ajax';
import { Loader2, Mail, ArrowLeft } from 'lucide-vue-next';

export default defineComponent({
    name: 'ForgotPassword',
    setup() {
        const email = ref('');
        const loading = ref(false);
        const successMessage = ref('');
        const errorMessage = ref('');

        useHead({ title: 'Forgot password' });

        const canSubmit = computed(() => email.value.trim().length > 0 && !loading.value);

        const submit = async () => {
            if (!canSubmit.value) return;
            loading.value = true;
            errorMessage.value = '';
            successMessage.value = '';

            try {
                const { data } = await ajax.post('/users/password.json', {
                    user: { email: email.value },
                }, {
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json',
                    },
                });

                successMessage.value = data?.message || 'If your email exists in our system, you will receive a password reset link shortly.';
            } catch (error: any) {
                const data = error?.response?.data;
                if (data?.message) {
                    successMessage.value = data.message;
                } else {
                    errorMessage.value =
                        data?.errors?.[0]
                        || data?.error
                        || 'Something went wrong. Please try again.';
                }
            } finally {
                loading.value = false;
            }
        };

        return () => (
            <div class="min-h-screen bg-[var(--c-primary-color)] text-[var(--c-body-text-color)]">
                <div class="mx-auto flex min-h-screen w-full max-w-md items-center px-4 py-8">
                    <div class="w-full rounded-2xl border border-[var(--c-primary-400)] bg-[var(--c-primary-600)] p-6 shadow-xl">

                        {successMessage.value ? (
                            <div class="text-center">
                                <div class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-emerald-500/10">
                                    <Mail size={22} class="text-emerald-400" />
                                </div>
                                <h1 class="text-xl font-semibold">Check your email</h1>
                                <p class="mt-2 text-sm text-emerald-400 leading-relaxed">
                                    {successMessage.value}
                                </p>
                                <a
                                    href="/"
                                    class="mt-6 inline-flex items-center gap-2 rounded-xl bg-[var(--c-tertiary-color)] px-5 py-2.5 text-sm font-semibold text-white transition-all hover:bg-[var(--c-tertiary-100)]"
                                >
                                    <ArrowLeft size={15} />
                                    Back to home
                                </a>
                            </div>
                        ) : (
                            <>
                                <div class="mb-6 text-center">
                                    <div class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-[var(--c-tertiary-color)]/10">
                                        <Mail size={22} class="text-[var(--c-tertiary-color)]" />
                                    </div>
                                    <h1 class="text-xl font-semibold">Forgot your password?</h1>
                                    <p class="mt-1 text-sm text-[var(--c-primary-100)]">
                                        Enter your email and we'll send you a reset link
                                    </p>
                                </div>

                                <form onSubmit={(e) => { e.preventDefault(); submit(); }} novalidate>
                                    <div>
                                        <label
                                            for="forgot-password-email-input"
                                            class="mb-1.5 block text-xs font-medium uppercase tracking-widest text-[var(--c-body-text-color)]"
                                        >
                                            Email
                                        </label>
                                        <input
                                            type="email"
                                            value={email.value}
                                            onInput={(e: any) => (email.value = e.target.value)}
                                            id="forgot-password-email-input"
                                            placeholder="you@example.com"
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

                                    <div class="mt-6 flex flex-col gap-3">
                                        <button
                                            type="submit"
                                            disabled={!canSubmit.value}
                                            class="inline-flex w-full items-center justify-center gap-2 rounded-xl bg-[var(--c-tertiary-color)] px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-all hover:bg-[var(--c-tertiary-100)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--c-tertiary-color)] disabled:cursor-not-allowed disabled:opacity-40"
                                        >
                                            {loading.value
                                                ? <Loader2 size={15} class="animate-spin" />
                                                : <Mail size={15} />
                                            }
                                            Send reset link
                                        </button>

                                        <a
                                            href="/"
                                            class="flex items-center justify-center gap-1 text-xs text-[var(--c-primary-100)] underline underline-offset-2 transition-colors hover:text-[var(--c-body-text-color)]"
                                        >
                                            <ArrowLeft size={12} />
                                            Back to home
                                        </a>
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
