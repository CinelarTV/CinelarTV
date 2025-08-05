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
                            class="dialog require-login w-full max-w-md transform overflow-hidden p-6 text-left align-middle shadow-xl transition-all">
                            <div class="image-container justify-center flex pb-4">
                                <img :src="SiteSettings.site_logo" class="modal-site-logo" />
                            </div>
                            <DialogTitle as="h3" class="text-lg font-medium text-center leading-6" v-emoji>
                                ¿Que estás esperando? 🍿
                            </DialogTitle>
                            <div class="mt-2">
                                <p class="text-sm mb-4 text-center" v-emoji>
                                    ¡Disfruta de todo el contenido de {{ SiteSettings.site_name }} creando una cuenta
                                    totalmente gratis!
                                    <br />
                                    <br />

                                    <RouterLink :to="{ path: '/login', replace: true }">
                                        <c-button icon="user" class="bg-blue-500 hover:bg-blue-600 text-white">
                                            Crear cuenta
                                        </c-button>
                                    </RouterLink>
                                    <br />
                                </p>
                            </div>
                        </DialogPanel>
                    </TransitionChild>
                </div>
            </div>
        </Dialog>
    </TransitionRoot>
</template>
  
<script setup>
import { ref, defineProps, defineEmits } from 'vue'
import {
    TransitionRoot,
    TransitionChild,
    Dialog,
    DialogPanel,
    DialogTitle,
    DialogDescription,
} from '@headlessui/vue'
import { ajax } from '../../lib/Ajax';

const isOpen = ref(false)
const emit = defineEmits(['openSignupModal', 'openLoginModal'])
const props = defineProps(['contentName'])

function setIsOpen(value) {
    isOpen.value = value
}


function signupModal() {
    emit('openSignupModal')
    console.log('signupModal')
}

defineExpose({
    setIsOpen
})
</script>../../lib/ajax