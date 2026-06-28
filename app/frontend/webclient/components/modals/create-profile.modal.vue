<template>
    <TransitionRoot appear :show="isOpen" as="template">
        <Dialog as="div" @close="setIsOpen(false)" class="relative z-100">
            <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0" enter-to="opacity-100"
                leave="duration-200 ease-in" leave-from="opacity-100" leave-to="opacity-0">
                <div class="fixed inset-0 bg-black/60 backdrop-blur-sm" />
            </TransitionChild>

            <div class="fixed inset-0 z-[102] flex items-center justify-center p-4">
                <TransitionChild as="template" enter="duration-300 ease-out"
                    enter-from="opacity-0 scale-95 translate-y-2" enter-to="opacity-100 scale-100 translate-y-0"
                    leave="duration-200 ease-in" leave-from="opacity-100 scale-100 translate-y-0"
                    leave-to="opacity-0 scale-95 translate-y-2">
                    <DialogPanel
                        class="w-full max-w-lg overflow-hidden rounded-2xl bg-[var(--c-primary-600)] shadow-2xl ring-1 ring-[var(--c-primary-400)]">
                        <div
                            class="border-b border-[var(--c-primary-200)] bg-[var(--c-primary-color)] px-8 pb-10 pt-8 text-center">
                            <img v-if="SiteSettings?.site_logo" :src="SiteSettings.site_logo"
                                class="mx-auto mb-5 h-10 w-auto" :alt="SiteSettings?.site_name || 'Site logo'" />

                            <DialogTitle as="h2"
                                class="text-xl font-semibold tracking-tight text-[var(--c-body-text-color)]" v-emoji>
                                Crea un perfil nuevo 🍿
                            </DialogTitle>
                            <p class="mt-1 text-sm text-[var(--c-primary-900)]">
                                Elige nombre y avatar para personalizar tu experiencia.
                            </p>
                        </div>

                        <div class="px-8 py-7">
                            <form id="create-profile-form" @submit="submitCreateProfile" novalidate>
                                <div class="space-y-4">
                                    <div>
                                        <label for="create-profile-name-input"
                                            class="mb-1.5 block text-xs font-medium uppercase tracking-widest text-[var(--c-primary-900)]">
                                            Nombre del perfil
                                        </label>
                                        <c-input type="text" v-model="name" id="create-profile-name-input"
                                            placeholder="Ej: Alex" />
                                    </div>

                                    <div>
                                        <label
                                            class="mb-2 block text-xs font-medium uppercase tracking-widest text-[var(--c-primary-900)]">
                                            Avatar
                                        </label>

                                        <div class="create-profile-modal__avatar-list">
                                            <button v-for="avatar in avatarList" :key="avatar.id" type="button"
                                                class="create-profile-modal__avatar"
                                                :class="{ 'selected': selectedAvatar === avatar.id }"
                                                @click="selectedAvatar = avatar.id"
                                                :aria-label="`Seleccionar avatar ${avatar.name}`">
                                                <img :src="avatar.path" :alt="avatar.name" />
                                            </button>
                                        </div>
                                    </div>
                                </div>

                                <div v-if="errors.length" class="create-profile-modal__errors">
                                    <p v-for="error in errors" :key="error">{{ error }}</p>
                                </div>

                                <div class="mt-6 flex items-center justify-end gap-3">
                                    <button type="button" class="create-profile-modal__cancel"
                                        @click="setIsOpen(false)">
                                        Cancelar
                                    </button>
                                    <button type="submit" :disabled="loading || !name.trim() || !selectedAvatar"
                                        class="create-profile-modal__submit">
                                        <template v-if="loading">
                                            <c-icon icon="loader" :size="16" class="animate-spin" />
                                        </template>
                                        <template v-else>
                                            <c-icon icon="plus" :size="16" />
                                        </template>
                                        Crear perfil
                                    </button>
                                </div>
                            </form>
                        </div>
                    </DialogPanel>
                </TransitionChild>
            </div>
        </Dialog>
    </TransitionRoot>
</template>

<script setup lang="ts">
import { ref, inject } from 'vue'
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'
import { ajax } from '../../lib/Ajax'
import CIcon from '../c-icon.vue'

const SiteSettings = inject<any>('SiteSettings')

type AvatarOption = {
    id: string
    name: string
    path: string
}

const props = withDefaults(defineProps<{
    avatarList?: AvatarOption[]
}>(), {
    avatarList: () => []
})

type CreatedProfile = {
    id: number
    name: string
    avatar_id?: string
    profile_type?: string
}

const emit = defineEmits<{
    created: [profile: CreatedProfile]
}>()

const isOpen = ref(false)
const loading = ref(false)
const name = ref('')
const selectedAvatar = ref('')
const errors = ref<string[]>([])

const resetState = () => {
    name.value = ''
    selectedAvatar.value = props.avatarList?.[0]?.id || ''
    errors.value = []
    loading.value = false
}

const setIsOpen = (value: boolean) => {
    isOpen.value = value
    if (value) {
        selectedAvatar.value = selectedAvatar.value || props.avatarList?.[0]?.id || ''
    } else {
        resetState()
    }
}

defineExpose({
    setIsOpen
})

const submitCreateProfile = async (e: Event) => {
    e.preventDefault()
    if (!name.value.trim() || !selectedAvatar.value || loading.value) return

    loading.value = true
    errors.value = []

    try {
        const response = await ajax.post('/user/create-profile.json', {
            name: name.value.trim(),
            avatar_id: selectedAvatar.value
        })

        const createdProfile = response?.data?.profile
        if (createdProfile?.id) {
            emit('created', createdProfile)
        }

        setIsOpen(false)
    } catch (error: any) {
        const serverErrors = error?.response?.data?.errors || error?.errors || []
        errors.value = Array.isArray(serverErrors)
            ? serverErrors
            : [serverErrors || 'No se pudo crear el perfil. Intenta nuevamente.']
        loading.value = false
    }
}
</script>