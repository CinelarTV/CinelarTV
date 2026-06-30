import { ref, computed, inject, defineComponent } from 'vue'
import {
  TransitionRoot,
  TransitionChild,
  Dialog,
  DialogPanel,
  DialogTitle,
} from '@headlessui/vue'
import { Unlock, Fingerprint, Loader2 } from 'lucide-vue-next'
import { ajax } from '../../lib/Ajax'
import CInput from '../forms/c-input.vue'

export default defineComponent({
  name: 'LoginModal',

  setup(_, { expose }) {
    const SiteSettings = inject<Record<string, any>>('SiteSettings')!

    const isOpen = ref(false)
    const email = ref('')
    const password = ref('')
    const loading = ref(false)
    const errorMessage = ref('')
    const isUnconfirmed = ref(false)
    const resendingConfirmation = ref(false)

    const canSubmit = computed(() => email.value && password.value && !loading.value)

    const hasExternalAuth = computed(
      () => SiteSettings.enable_cas_login || SiteSettings.enable_oauth_login,
    )

    const setIsOpen = (value: boolean) => {
      isOpen.value = value
      if (!value) {
        email.value = ''
        password.value = ''
        loading.value = false
        errorMessage.value = ''
        isUnconfirmed.value = false
        resendingConfirmation.value = false
      }
    }

    const submitLogin = async () => {
      if (!canSubmit.value) return
      loading.value = true
      errorMessage.value = ''
      isUnconfirmed.value = false
      try {
        await ajax.post('/login.json', {
          user: { email: email.value, password: password.value, remember_me: true },
        })
        window.location.reload()
      } catch (error: any) {
        const errorType = error.response?.data?.error_type
        if (errorType === 'unconfirmed') {
          isUnconfirmed.value = true
          errorMessage.value = error.response?.data?.errors?.[0] || 'You have to confirm your email address before continuing.'
        } else {
          errorMessage.value = error.response?.data?.errors?.[0] || 'An error occurred during login. Please try again.'
        }
      } finally {
        loading.value = false
      }
    }

    const resendConfirmation = async () => {
      if (!email.value) return
      resendingConfirmation.value = true
      try {
        await ajax.post('/confirmation.json', {
          user: { email: email.value },
        })
        errorMessage.value = 'Confirmation email sent successfully. Please check your inbox.'
      } catch (error: any) {
        errorMessage.value = error.response?.data?.error || 'Failed to resend confirmation email. Please try again.'
      } finally {
        resendingConfirmation.value = false
      }
    }

    const forgotPassword = () => {
      // TODO: Implement forgot password
    }

    const casLogin = () => {
      // TODO: Implement CAS login
    }

    expose({ setIsOpen })

    return () => (
      <TransitionRoot appear show={isOpen.value} as="template">
        <Dialog as="div" onClose={() => setIsOpen(false)} class="relative z-100">

          {/* Backdrop */}
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

          {/* Modal container */}
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
              <DialogPanel class="w-full max-w-sm rounded-2xl overflow-hidden shadow-2xl ring-1 ring-[var(--c-primary-400)] bg-[var(--c-primary-600)]">

                {/* Header */}
                <div class="bg-[var(--c-primary-color)] px-8 pt-8 pb-10 text-center border-b border-[var(--c-primary-400)]">
                  {SiteSettings.site_logo && (
                    <img
                      src={SiteSettings.site_logo}
                      alt={SiteSettings.site_name}
                      class="mx-auto h-10 w-auto mb-5"
                    />
                  )}
                  <DialogTitle as="h2" class="text-xl font-semibold tracking-tight text-[var(--c-body-text-color)]">
                    Welcome back
                  </DialogTitle>
                  <p class="mt-1 text-sm text-[var(--c-body-text-color)]">
                    Sign in to {SiteSettings.site_name}
                  </p>
                </div>

                {/* Form */}
                <div class="px-8 py-7">
                  <form onSubmit={(e) => { e.preventDefault(); submitLogin() }} novalidate>

                    <div class="space-y-4">
                      <div>
                        <label
                          for="login-email-input"
                          class="block text-xs font-medium uppercase tracking-widest text-[var(--c-body-text-color)] mb-1.5"
                        >
                          Email
                        </label>
                        <CInput
                          type="email"
                          modelValue={email.value}
                          onUpdate:modelValue={(v: string) => (email.value = v)}
                          id="login-email-input"
                          placeholder="you@example.com"
                          required
                        />
                      </div>

                      <div>
                        <label
                          for="login-password-input"
                          class="block text-xs font-medium uppercase tracking-widest text-[var(--c-body-text-color)] mb-1.5"
                        >
                          Password
                        </label>
                        <CInput
                          type="password"
                          modelValue={password.value}
                          onUpdate:modelValue={(v: string) => (password.value = v)}
                          id="login-password-input"
                          placeholder="••••••••"
                          required
                        />
                      </div>
                    </div>

                    {errorMessage.value && (
                      <p class={`mt-3 text-xs font-medium ${isUnconfirmed.value ? 'text-amber-400' : 'text-rose-400'}`}>
                        {errorMessage.value}
                      </p>
                    )}

                    {isUnconfirmed.value && (
                      <button
                        type="button"
                        onClick={resendConfirmation}
                        disabled={resendingConfirmation.value}
                        class="mt-3 w-full inline-flex items-center justify-center gap-2 rounded-xl bg-amber-500/10 border border-amber-500/30 px-4 py-2.5 text-sm font-medium text-amber-400 transition-all hover:bg-amber-500/20 disabled:cursor-not-allowed disabled:opacity-40"
                      >
                        {resendingConfirmation.value
                          ? <Loader2 size={15} class="animate-spin" />
                          : 'Resend confirmation email'
                        }
                      </button>
                    )}

                    <div class="mt-6 flex items-center justify-between gap-3">
                      <button
                        type="button"
                        onClick={forgotPassword}
                        class="text-xs text-[var(--c-tertiary-color)] underline underline-offset-2 transition-colors hover:text-[var(--c-body-text-color)]"
                      >
                        Forgot password?
                      </button>

                      <button
                        type="submit"
                        disabled={!canSubmit.value}
                        class="inline-flex items-center gap-2 rounded-xl bg-[var(--c-tertiary-color)] px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-all hover:bg-[var(--c-tertiary-100)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--c-tertiary-color)] disabled:cursor-not-allowed disabled:opacity-40"
                      >
                        {loading.value
                          ? <Loader2 size={15} class="animate-spin" />
                          : <Unlock size={15} />
                        }
                        Sign in
                      </button>
                    </div>

                    {hasExternalAuth.value && (
                      <div class="mt-6">
                        <div class="relative flex items-center">
                          <div class="flex-grow border-t border-[var(--c-primary-400)]" />
                          <span class="mx-3 text-xs text-[var(--c-primary-100)]">or continue with</span>
                          <div class="flex-grow border-t border-[var(--c-primary-400)]" />
                        </div>

                        <div class="mt-4 flex flex-col gap-2">
                          {SiteSettings.enable_cas_login && (
                            <button
                              type="button"
                              onClick={casLogin}
                              class="flex w-full items-center justify-center gap-2 rounded-xl border border-[var(--c-primary-300)] bg-[var(--c-primary-200)] px-4 py-2.5 text-sm font-medium text-[var(--c-body-text-color)] transition-all hover:bg-[var(--c-primary-300)]"
                            >
                              <Fingerprint size={16} class="text-[var(--c-primary-100)]" />
                              Continue with CAS
                            </button>
                          )}
                        </div>
                      </div>
                    )}

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