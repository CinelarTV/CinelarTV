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
                            class="dialog edit-season w-full max-w-md transform overflow-hidden p-6 text-left align-middle shadow-xl transition-all">
                            <DialogTitle as="h3" class="text-lg font-medium leading-6 text-[var(--primary-600)]" v-emoji>
                                Editar temporada
                            </DialogTitle>

                            <form @submit="submitUpdateSeason">
                                <div class="mt-4">
                                    <label for="name" class="block text-sm font-medium">
                                        Nombre
                                    </label>
                                    <div class="mt-1">
                                        <c-input :modelValue="seasonData.name"
                                            @update:modelValue="value => seasonData.name = value"
                                            class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                                            placeholder="Temporada 1" />
                                    </div>
                                </div>
                            </form>

                            <div class="flex mt-4 justify-center space-x-4">
                                <c-button @click="submitUpdateSeason" :loading="loading">
                                    <CheckIcon :size="18" class="icon" v-if="!loading" />
                                    Guardar cambios
                                </c-button>
                            </div>
                        </DialogPanel>
                    </TransitionChild>
                </div>
            </div>
        </Dialog>
    </TransitionRoot>
</template>

<script setup>
import { ref, inject } from 'vue'
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'
import { CheckIcon } from 'lucide-vue-next';
import { toast } from 'vue3-toastify';
import { ajax } from '../../lib/Ajax';

const i18n = inject('I18n');

const emit = defineEmits(['season-updated'])

const props = defineProps({
    contentId: String,
})

const isOpen = ref(false)
const loading = ref(false)
const seasonData = ref({
    id: '',
    name: '',
})

const setIsOpen = (value, season = null) => {
    if (season) {
        seasonData.value.id = season.id
        seasonData.value.name = season.title
    }
    isOpen.value = value
}

defineExpose({
    setIsOpen
})

const submitUpdateSeason = (e) => {
    e.preventDefault()
    loading.value = true

    const data = {
        season: {
            title: seasonData.value.name,
        }
    }

    ajax.put(`/admin/content-manager/${props.contentId}/seasons/${seasonData.value.id}`, data)
        .then(response => {
            toast.success('Temporada actualizada con éxito')
            emit('season-updated', response)
        })
        .catch(error => {
            toast.error('Error al actualizar la temporada: ' + error.message)
            console.log(error)
        })
        .finally(() => {
            loading.value = false
            setIsOpen(false)
        })
}
</script>
