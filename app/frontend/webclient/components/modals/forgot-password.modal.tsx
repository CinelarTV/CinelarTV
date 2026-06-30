import { ref, computed, defineComponent } from 'vue'
import {
  TransitionRoot,
  TransitionChild,
  Dialog,
  DialogPanel,
  DialogTitle,
} from '@headlessui/vue'
import { Loader2, Mail } from 'lucide-vue-next'
import { ajax } from '../../lib/Ajax'

export default defineComponent({
  name: 'ForgotPasswordModal',

  setup(_, { expose }) {
    const isOpen = ref(false)
    const email = ref('')
    const loading = ref(false)
    const errorMessage = ref('')
    const successMessage = ref('')

    const canSubmit = computed(() => email.value.trim().length > 0 && !loading.value)

    const setIsOpen = (value: boolean) => {
      isOpen.value = value
      if (!value) {
        email.value = ''
        loading.value = false
        errorMessage.value = ''
        successMessage.value = ''
      }
    }

    const submitForgotPassword = async () => {
      if (!canSubmit.value) return
      loading.value = true
      errorMessage.value = ''
      successMessage.value = ''

      try {
        const response = await ajax.post('/users/password.json', {
          user: { email: email.value },
        }, {
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        })

        successMessage.value = response.data?.message || 'If your email exists in our system, you will receive a password reset link shortly.'
      } catch (error: any) {
        const data = error?.response?.data
        if (data?.message) {
          successMessage.value = data.message
        } else {
          errorMessage.value =
            data?.errors?.[0]
            || data?.error
            || 'Something went wrong. Please try again.'
        }
      } finally {
        loading.value = false
      }
    }

    const goToLogin = () => {
      setIsOpen(false)
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
              <DialogPanel class="w-full max-w-sm rounded-2xl overflow-hidden shadow-2xl ring-1 ring-[var(--c-primary-400)] bg-[var(--c-primary-600)]">

                <div class="bg-[var(--c-primary-color)] px-8 pt-8 pb-10 text-center border-b border-[var(--c-primary-400)]">
                  <div class="mx-auto mb-5 flex h-12 w-12 items-center justify-center rounded-full bg-[var(--c-tertiary-color)]/10">
                    <Mail size={22} class="text-[var(--c-tertiary-color)]" />
                  </div>
                  <DialogTitle as="h2" class="text-xl font-semibold tracking-tight text-[var(--c-body-text-color)]">
                    Forgot your password?
                  </DialogTitle>
                  <p class="mt-1 text-sm text-[var(--c-body-text-color)]">
                    Enter your email and we'll send you a reset link
                  </p>
                </div>

                <div class="px-8 py-7">
                  {successMessage.value ? (
                    <div class="text-center">
                      <p class="text-sm text-emerald-400 leading-relaxed">
                        {successMessage.value}
                      </p>
                      <button
                        type="button"
                        onClick={goToLogin}
                        class="mt-6 w-full rounded-xl bg-[var(--c-tertiary-color)] px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-all hover:bg-[var(--c-tertiary-100)]"
                      >
                        Back to sign in
                      </button>
                    </div>
                  ) : (
                    <form onSubmit={(e) => { e.preventDefault(); submitForgotPassword() }} novalidate>

                      <div>
                        <label
                          for="forgot-password-email-input"
                          class="block text-xs font-medium uppercase tracking-widest text-[var(--c-body-text-color)] mb-1.5"
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

                        <button
                          type="button"
                          onClick={goToLogin}
                          class="text-xs text-[var(--c-primary-100)] underline underline-offset-2 transition-colors hover:text-[var(--c-body-text-color)]"
                        >
                          Back to sign in
                        </button>
                      </div>

                    </form>
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
