import { computed, defineComponent, inject, ref } from 'vue'
import {
    TransitionRoot,
    TransitionChild,
    Dialog,
    DialogPanel,
    DialogTitle,
} from '@headlessui/vue'
import { ajax } from '../../lib/Ajax'
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
        }

        const setIsOpen = (value: boolean) => {
            isOpen.value = value
            if (!value) resetForm()
        }

        const submitRegistration = async () => {
            if (!canSubmit.value) return

            loading.value = true
            errorMessage.value = ''

            try {
                await ajax.post('/signup.json', {
                    user: {
                        username: username.value,
                        email: email.value,
                        password: password.value,
                        password_confirmation: password.value,
                    },
                })

                setIsOpen(false)
                window.location.reload()
            } catch (error: any) {
                errorMessage.value =
                    error?.response?.data?.message
                    || error?.response?.data?.error
                    || 'Could not create account. Please verify your data and try again.'
            } finally {
                loading.value = false
            }
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
                            <DialogPanel class="w-full max-w-md overflow-hidden rounded-2xl bg-[var(--c-primary-100)] shadow-2xl ring-1 ring-[var(--c-primary-200)]">

                                <div class="border-b border-[var(--c-primary-200)] bg-[var(--c-primary-color)] px-8 pb-10 pt-8 text-center">
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
                                    <p class="mt-1 text-sm text-[var(--c-primary-900)]">
                                        Join {SiteSettings.site_name}
                                    </p>
                                </div>

                                <div class="px-8 py-7">
                                    <form onSubmit={(e) => { e.preventDefault(); submitRegistration() }} novalidate>

                                        <div class="space-y-4">
                                            <div>
                                                <label
                                                    for="signup-username-input"
                                                    class="mb-1.5 block text-xs font-medium uppercase tracking-widest text-[var(--c-primary-900)]"
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
                                                    class="mb-1.5 block text-xs font-medium uppercase tracking-widest text-[var(--c-primary-900)]"
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
                                                    class="mb-1.5 block text-xs font-medium uppercase tracking-widest text-[var(--c-primary-900)]"
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
                                </div>

                            </DialogPanel>
                        </TransitionChild>
                    </div>

                </Dialog>
            </TransitionRoot>
        )
    },
})
