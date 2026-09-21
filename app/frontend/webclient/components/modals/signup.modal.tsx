import { computed, defineComponent, inject, ref } from 'vue'
import {
  TransitionRoot,
  TransitionChild,
  Dialog,
  DialogPanel,
  DialogTitle,
} from '@headlessui/vue'
import { ajax, fetchCsrfToken } from '../../lib/Ajax'
import CIcon from '../c-icon.vue'

export default defineComponent({
    name: 'SignupModal',

    setup(_, { expose }) {
        const SiteSettings = inject<Record<string, any>>('SiteSettings')!

        const isOpen = ref(false)
        const username = ref('')
        const email = ref('')
        const password = ref('')
        const loading = ref(false)
        const errorMessage = ref('')
        const successMessage = ref('')

        const canSubmit = computed(() => {
            return (
                username.value.trim().length >= 3
                && email.value.trim().length > 0
                && password.value.length >= 6
                && !loading.value
            )
        })

        const resetForm = () => {
            username.value = ''
            email.value = ''
            password.value = ''
            loading.value = false
            errorMessage.value = ''
            successMessage.value = ''
        }

        const setIsOpen = (value: boolean) => {
            isOpen.value = value
            if (!value) resetForm()
        }

        const submitRegistration = async () => {
            if (!canSubmit.value) return

            loading.value = true
            errorMessage.value = ''
            successMessage.value = ''

            try {
                const response = await ajax.post('/signup.json', {
                    user: {
                        username: username.value,
                        email: email.value,
                        password: password.value,
                        password_confirmation: password.value,
                    },
                }, {
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json'
                    }
                })

                const needsConfirmation = response.data?.needs_confirmation !== false

                if (needsConfirmation) {
                    successMessage.value = response.data?.message || 'Registration successful. Please check your email to confirm your account.'
                    username.value = ''
                    email.value = ''
                    password.value = ''
                } else {
                    setIsOpen(false)
                    window.location.href = '/'
                }
            } catch (error: any) {
                errorMessage.value =
                    error?.response?.data?.message
                    || error?.response?.data?.error
                    || 'Could not create account. Please verify your data and try again.'
            } finally {
                loading.value = false
            }
        }

const handleGoogleLogin = async () => {
            // Fetch fresh CSRF token (critical for anonymous login to avoid CSRF errors)
            const csrfToken = await fetchCsrfToken();

            const form = document.createElement('form')
            // OmniAuth 2 only starts strategies on POST requests. The CSRF token
            // below is validated by omniauth-rails_csrf_protection.
            form.method = 'POST'
            form.action = '/auth/google_oauth2'

            const input = document.createElement('input')
            input.type = 'hidden'
            input.name = 'authenticity_token'
            input.value = csrfToken
            form.appendChild(input)

            document.body.appendChild(form)
            form.submit()
        }

        expose({ setIsOpen })

        return () => (
            <TransitionRoot appear show={isOpen.value} as="template">
                <Dialog as="div" onClose={() => setIsOpen(false)} class="relative z-100">

                    <TransitionChild
                        as="template"
                        enter="duration-300 ease-out"
                        enterFrom="opacity-0"
                        enterTo="opacity-100"
                        leave="duration-200 ease-in"
                        leaveFrom="opacity-100"
                        leaveTo="opacity-0"
                    >
                        <div class="fixed inset-0 bg-black/60 backdrop-blur-sm" />
                    </TransitionChild>

                    <div class="fixed inset-0 flex items-center justify-center p-4">
                        <TransitionChild
                            as="template"
                            enter="duration-300 ease-out"
                            enterFrom="opacity-0 scale-95 translate-y-2"
                            enterTo="opacity-100 scale-100 translate-y-0"
                            leave="duration-200 ease-in"
                            leaveFrom="opacity-100 scale-100 translate-y-0"
                            leaveTo="opacity-0 scale-95 translate-y-2"
                        >
                            <DialogPanel class="w-full max-w-md overflow-hidden rounded-2xl bg-[var(--c-primary-600)] shadow-2xl ring-1 ring-[var(--c-primary-400)]">

                                <div class="border-b border-[var(--c-primary-400)] bg-[var(--c-primary-color)] px-8 pb-10 pt-8 text-center">
                                    {SiteSettings.site_logo && (
                                        <img
                                            src={SiteSettings.site_logo}
                                            alt={SiteSettings.site_name}
                                            class="mx-auto mb-5 h-10 w-auto"
                                        />
                                    )}
                                    <DialogTitle as="h2" class="text-xl font-semibold tracking-tight text-[var(--c-body-text-color)]">
                                        Create your account
                                    </DialogTitle>
                                    <p class="mt-1 text-sm text-[var(--c-body-text-color)]">
                                        Join {SiteSettings.site_name}
                                    </p>
                                </div>

                                <div class="px-8 py-7">
                                    <form onSubmit={(e) => { e.preventDefault(); submitRegistration() }} novalidate>

                                        <div class="space-y-4">
                                            <div>
                                                <label
                                                    for="signup-username-input"
                                                    class="mb-1.5 block text-xs font-medium uppercase tracking-widest text-[var(--c-body-text-color)]"
                                                >
                                                    Username
                                                </label>
                                                <input
                                                    type="text"
                                                    value={username.value}
                                                    onInput={(e: any) => (username.value = e.target.value)}
                                                    id="signup-username-input"
                                                    placeholder="your_username"
                                                    class="c-input"
                                                    required
                                                />
                                            </div>

                                            <div>
                                                <label
                                                    for="signup-email-input"
                                                    class="mb-1.5 block text-xs font-medium uppercase tracking-widest text-[var(--c-body-text-color)]"
                                                >
                                                    Email
                                                </label>
                                                <input
                                                    type="email"
                                                    value={email.value}
                                                    onInput={(e: any) => (email.value = e.target.value)}
                                                    id="signup-email-input"
                                                    placeholder="you@example.com"
                                                    class="c-input"
                                                    required
                                                />
                                            </div>

                                            <div>
                                                <label
                                                    for="signup-password-input"
                                                    class="mb-1.5 block text-xs font-medium uppercase tracking-widest text-[var(--c-body-text-color)]"
                                                >
                                                    Password
                                                </label>
                                                <input
                                                    type="password"
                                                    value={password.value}
                                                    onInput={(e: any) => (password.value = e.target.value)}
                                                    id="signup-password-input"
                                                    placeholder="At least 6 characters"
                                                    class="c-input"
                                                    required
                                                />
                                            </div>
                                        </div>

                                        {successMessage.value && (
                                            <p class="mt-3 text-xs font-medium text-emerald-400">
                                                {successMessage.value}
                                            </p>
                                        )}

                                        {errorMessage.value && (
                                            <p class="mt-3 text-xs font-medium text-rose-400">
                                                {errorMessage.value}
                                            </p>
                                        )}

                                        <div class="mt-6 flex items-center justify-end gap-3">
                                            <button
                                                type="submit"
                                                disabled={!canSubmit.value}
                                                class="inline-flex items-center gap-2 rounded-xl bg-[var(--c-tertiary-color)] px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-all hover:bg-[var(--c-tertiary-100)] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--c-tertiary-color)] disabled:cursor-not-allowed disabled:opacity-40"
                                            >
                                                {loading.value
                                                    ? <CIcon icon="loader" size={15} class="animate-spin" />
                                                    : <CIcon icon="user" size={15} />
                                                }
                                                Sign up
                                            </button>
                                        </div>

                                    </form>

                                    {SiteSettings.enable_google_login && (
                                        <div class="mt-6">
                                            <div class="relative flex items-center">
                                                <div class="flex-grow border-t border-[var(--c-primary-400)]" />
                                                <span class="mx-3 text-xs text-[var(--c-primary-100)]">or continue with</span>
                                                <div class="flex-grow border-t border-[var(--c-primary-400)]" />
                                            </div>

                                            <div class="mt-4">
                                                <button
                                                    type="button"
                                                    onClick={handleGoogleLogin}
                                                    class="flex w-full items-center justify-center gap-2 rounded-xl border border-[var(--c-primary-300)] bg-[var(--c-primary-200)] px-4 py-2.5 text-sm font-medium text-[var(--c-body-text-color)] transition-all hover:bg-[var(--c-primary-300)]"
                                                >
                                                    <svg viewBox="0 0 24 24" class="h-4 w-4 shrink-0">
                                                        <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 01-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4"/>
                                                        <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                                                        <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
                                                        <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
                                                    </svg>
                                                    Sign up with Google
                                                </button>
                                            </div>
                                        </div>
                                    )}
                                </div>

                            </DialogPanel>
                        </TransitionChild>
                    </div>

                </Dialog>
            </TransitionRoot>
        )
    },
})
