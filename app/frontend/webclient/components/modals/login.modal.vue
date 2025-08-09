<template>
    <TransitionRoot appear :show="isOpen" as="template">
        <Dialog as="div" @close="setIsOpen(false)" class="modal">
            <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0" enter-to="opacity-100"
                leave="duration-200 ease-in" leave-from="opacity-100" leave-to="opacity-0">
                <div class="fixed inset-0 bg-black/25 z-[101]" />
            </TransitionChild>

            <div class="fixed inset-0 overflow-y-auto z-[102]">
                <div class="flex min-h-full items-center justify-center p-4 text-center">
                    <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0 scale-95"
                        enter-to="opacity-100 scale-100" leave="duration-200 ease-in" leave-from="opacity-100 scale-100"
                        leave-to="opacity-0 scale-95">
                        <DialogPanel
                            class="dialog login w-full max-w-md transform overflow-hidden p-6 text-left align-middle shadow-xl transition-all">
                            <div class="image-container justify-center flex pb-4">
                                <img :src="SiteSettings.site_logo" class="modal-site-logo" />
                            </div>
                            <DialogTitle as="h3"
                                class="text-lg font-medium text-center leading-6 text-[var(--c-primary-800)]" v-emoji>
                                Welcome back to {{ SiteSettings.site_name }} 👋!
                            </DialogTitle>
                            <div class="mt-2">
                                <form @submit.prevent="submitLogin">
                                    <c-input type="email" v-model="email" id="login-email-input" placeholder="E-mail"
                                        class="mb-4" required />
                                    <c-input type="password" v-model="password" id="login-password-input"
                                        placeholder="Password" required />

                                    <div class="mt-4 flex items-center space-x-6 justify-center">
                                        <button type="button" @click="forgotPassword"
                                            class="button dark forgot-password">
                                            Forgot password
                                        </button>
                                        <button type="submit" class="button login-button"
                                            :disabled="loading || !canSubmit">
                                            <LoaderIcon v-if="loading" :size="18" class="icon loading-request" />
                                            <Unlock v-else :size="18" class="icon" />
                                            Login
                                        </button>
                                    </div>

                                    <footer v-if="hasExternalAuth" class="mt-4">
                                        <hr class="separator" />
                                        <div class="external-auth-providers">
                                            <button v-if="SiteSettings.enable_cas_login" type="button" @click="casLogin"
                                                class="auth-provider">
                                                <Fingerprint class="icon" :size="20" />
                                                Login with CAS
                                            </button>
                                        </div>
                                    </footer>
                                </form>
                            </div>
                        </DialogPanel>
                    </TransitionChild>
                </div>
            </div>
        </Dialog>
    </TransitionRoot>
</template>

<script setup>
import { ref, computed, inject } from 'vue'
import {
    TransitionRoot,
    TransitionChild,
    Dialog,
    DialogPanel,
    DialogTitle,
} from '@headlessui/vue'
import { Unlock, Fingerprint, LoaderIcon } from 'lucide-vue-next'
import { ajax } from '../../lib/Ajax'
import cInput from "../forms/c-input.vue"

// Inject dependencies
const SiteSettings = inject('SiteSettings')

// Reactive state
const isOpen = ref(false)
const email = ref('')
const password = ref('')
const loading = ref(false)

// Computed properties
const canSubmit = computed(() => {
    return email.value && password.value && !loading.value
})

const hasExternalAuth = computed(() => {
    return SiteSettings.enable_cas_login || SiteSettings.enable_oauth_login
})

// Methods
const setIsOpen = (value) => {
    isOpen.value = value
    if (!value) {
        // Reset form when closing
        email.value = ''
        password.value = ''
        loading.value = false
    }
}

const submitLogin = async () => {
    if (!canSubmit.value) return

    loading.value = true

    try {
        await ajax.post('/login.json', {
            user: {
                email: email.value,
                password: password.value,
                remember_me: true
            }
        })

        // Success - reload page
        window.location.reload()
    } catch (error) {
        console.error('Login error:', error)
        // TODO: Show error message to user
    } finally {
        loading.value = false
    }
}

const forgotPassword = () => {
    // TODO: Implement forgot password functionality
    console.log('Forgot password clicked')
}

const casLogin = () => {
    // TODO: Implement CAS login
    console.log('CAS login clicked')
}

// Expose methods for parent components
defineExpose({
    setIsOpen
})
</script>