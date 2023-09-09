<template>
    <TransitionRoot appear :show="isOpen" as="template">
        <Dialog as="div" @close="setIsOpen(false)" class="modal">
            <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0" enter-to="opacity-100"
                leave="duration-200 ease-in" leave-from="opacity-100" leave-to="opacity-0">
                <div class="fixed inset-0 bg-black bg-opacity-25 z-[101]" />
            </TransitionChild>

            <div class="fixed inset-0 overflow-y-auto z-[102]">
                <div class="flex min-h-full items-center justify-center p-4 text-center">
                    <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0 scale-95"
                        enter-to="opacity-100 scale-100" leave="duration-200 ease-in" leave-from="opacity-100 scale-100"
                        leave-to="opacity-0 scale-95">
                        <DialogPanel
                            class="dialog register w-full max-w-md transform overflow-hidden rounded-2xl p-6 text-left align-middle shadow-xl transition-all">
                            <div class="image-container justify-center flex pb-4">
                                <img :src="SiteSettings.site_logo" class="modal-site-logo" />
                            </div>
                            <DialogTitle as="h3"
                                class="text-lg font-medium text-center leading-6 text-[var(--c-primary-800)]" v-emoji>
                                Join {{ SiteSettings.site_name }} 🎉!
                            </DialogTitle>
                            <div class="mt-2">
                                <p class="text-sm text-gray-500 mb-4">
                                    <!-- Your registration description here -->
                                </p>

                                <form id="register-form" @submit="console.log(e)" type="POST">
                                    <c-input type="text" v-model="username" id="register-username-input"
                                        placeholder="Username" class="mb-4" />
                                    <c-input type="email" v-model="email" id="register-email-input" placeholder="E-mail"
                                        class="mb-4" />
                                    <c-input type="password" v-model="password" id="register-password-input"
                                        placeholder="Password" />

                                    <div class="mt-4 flex items-center space-x-6 justify-center">
                                        <button type="submit" class="button register-button" @click="submitRegistration">
                                            <template v-if="loading">
                                                <LoaderIcon :size="18" class="icon loading-request" />
                                            </template>
                                            <template v-else>
                                                <Unlock :size="18" class="icon" />
                                            </template>
                                            Register
                                        </button>
                                    </div>
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
import { ref } from 'vue'
import {
    TransitionRoot,
    TransitionChild,
    Dialog,
    DialogPanel,
    DialogTitle,
    DialogDescription,
} from '@headlessui/vue'
import { Unlock, LoaderIcon } from 'lucide-vue-next'
import { ajax } from '../../lib/axios-setup';

const isOpen = ref(false)
const username = ref('')
const email = ref('')
const password = ref('')
const loading = ref(false)

function setIsOpen(value) {
    isOpen.value = value
}

function submitRegistration(e) {
    e.preventDefault()
    loading.value = true
    ajax
        .post('/users.json', {
            user: {
                username: username.value,
                email: email.value,
                password: password.value,
                password_confirmation: password.value,
            },
        })
        .then((res) => {
            loading.value = false
            setIsOpen(false)
            window.location.reload()
            // Handle successful registration
        })
        .catch((e) => {
            loading.value = false
            console.error(e)
        })
}

defineExpose({
    setIsOpen,
})
</script>