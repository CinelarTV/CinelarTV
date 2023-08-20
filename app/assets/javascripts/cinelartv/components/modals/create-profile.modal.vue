<template>
    <TransitionRoot appear :show="isOpen" as="template">
        <Dialog as="div" @close="setIsOpen(false)" class="modal">
            <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0" enter-to="opacity-100"
                leave="duration-200 ease-in" leave-from="opacity-100" leave-to="opacity-0">
                <div class="fixed inset-0 bg-black bg-opacity-95 z-[101]" />
            </TransitionChild>

            <div class="fixed inset-0 overflow-y-auto z-[102]">
                <div class="flex min-h-full items-center justify-center p-4 text-center">
                    <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0 scale-95"
                        enter-to="opacity-100 scale-100" leave="duration-200 ease-in" leave-from="opacity-100 scale-100"
                        leave-to="opacity-0 scale-95">
                        <DialogPanel
                            class="dialog create-profile w-full max-w-md transform overflow-hidden rounded-2xl p-6 text-left align-middle shadow-xl transition-all">
                            <div class="image-container justify-center flex pb-4">
                                <img :src="SiteSettings.site_logo" class="modal-site-logo" />
                            </div>
                            <DialogTitle as="h3" class="text-lg font-medium leading-6 text-gray-900" v-emoji>
                                ¡Crea un perfil nuevo! 🍿
                            </DialogTitle>
                            <div class="mt-2">
                                <p class="text-sm text-gray-500 mb-4">
                                    ¿Quién eres? 🍿
                                </p>

                                <form id="create-profile-form" @submit="console.log(e)" type="POST">
                                    <input type="text" v-model="name" id="create-profile-name-input" placeholder="Nombre"
                                        class="mb-4" />
                                    <input type="text" v-model="avatar" id="create-profile-avatar-input"
                                        placeholder="Avatar" />

                                    <div class="mt-4">
                                        <button type="submit" class="create-profile-button" @click="submitCreateProfile">
                                            <template v-if="loading">
                                                <LoaderIcon :size="18" class="icon loading-request" />
                                            </template>
                                            <template v-else>
                                                <Unlock :size="18" class="icon" />
                                            </template>
                                            Crear perfil
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
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'
import { SiteSettings, currentUser } from '../../pre-initializers/essentials-preload';
import { Unlock, LoaderIcon } from 'lucide-vue-next'

const isOpen = ref(false)
const loading = ref(false)
const name = ref('')
const avatar = ref('')


const setIsOpen = (value) => {
    isOpen.value = value
}

defineExpose({
    setIsOpen
})

const submitCreateProfile = () => {
    loading.value = true

    const data = {
        name: name.value,
        avatar: avatar.value
    }

    axios.post('/user/create-profile', data)
        .then((response) => {
            console.log(response)
            loading.value = false
            setIsOpen(false)
        })
        .catch((error) => {
            console.log(error)
            loading.value = false
        })
}

</script>
