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
                            class="dialog create-profile w-full max-w-md transform overflow-hidden p-6 text-left align-middle shadow-xl transition-all">
                            <template v-if="errors">
                                <div class="alert alert-danger">
                                    <template v-for="error in errors">
                                        <p>{{ error }}</p>
                                    </template>
                                </div>
                            </template>
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

                                <form id="create-profile-form" @submit="submitCreateProfile" type="POST">
                                    <c-input type="text" v-model="name" id="create-profile-name-input" placeholder="Nombre"
                                        class="mb-4" />
                                    <div class="avatar-list">
                                        <template v-for="avatar in avatarList">
                                            <div class="avatar" @click="selectedAvatar = avatar.id" :class="{ 'selected': selectedAvatar === avatar.id }">
                                                <img :src="avatar.path" :alt="avatar.name" />
                                            </div>
                                        </template>
                                    </div>

                                    <div class="mt-4">
                                        <button type="submit" class="button">
                                            <template v-if="loading">
                                                <LoaderIcon :size="18" class="icon loading-request" />
                                            </template>
                                            <template v-else>
                                                <PlusIcon :size="18" class="icon" />
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
import { onMounted, ref, inject } from 'vue'
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'
import { Unlock, LoaderIcon } from 'lucide-vue-next'
import { PlusIcon } from 'lucide-vue-next';
import { ajax } from '../../lib/axios-setup';

const SiteSettings = inject('SiteSettings')
const currentUser = inject('currentUser')

const props = defineProps({
    avatarList: {
        type: Array,
        default: []
    }
})

const isOpen = ref(false)
const loading = ref(false)
const name = ref('')
const selectedAvatar = ref('')
const errors = ref()


const setIsOpen = (value) => {
    isOpen.value = value
}

defineExpose({
    setIsOpen
})

const submitCreateProfile = (e) => {
    e.preventDefault()
    loading.value = true
    errors.value = null

    const data = {
        name: name.value,
        avatar_id: selectedAvatar.value
    }

    ajax.post('/user/create-profile.json', data)
        .then((response) => {
            loading.value = false
            setIsOpen(false)
            window.location.reload()
        })
        .catch((error) => {
            loading.value = false
            errors.value = error.errors
        })
}

</script>
