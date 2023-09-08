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
                            class="dialog create-season w-full max-w-md transform overflow-hidden rounded-2xl p-6 text-left align-middle shadow-xl transition-all">
                            <!-- Your season creation form here -->
                            <DialogTitle as="h3" class="text-lg font-medium leading-6 text-[var(--primary-600)]" v-emoji>
                                Create a New Season 🌟
                            </DialogTitle>

                            <form @submit="submitCreateSeason">
                                <div class="mt-4">
                                    <label for="name" class="block text-sm font-medium">
                                        Name
                                    </label>
                                    <div class="mt-1">
                                        <c-input :modelValue="seasonData.name"
                                            @update:modelValue="value => seasonData.name = value"
                                            class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                                            placeholder="Season 1" />
                                    </div>

                                    <!-- You can add more fields for season details as needed -->

                                </div>
                            </form>

                            <div class="flex mt-2 justify-center space-x-4">
                                <c-button @click="submitCreateSeason" :loading="loading">
                                    <CheckIcon :size="18" class="icon" v-if="!loading" />
                                    Create season
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
import { getCurrentInstance, onMounted, ref, inject } from 'vue'
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'
import { CheckIcon } from 'lucide-vue-next';
import { toast } from 'vue3-toastify';
import { ajax } from '../../lib/axios-setup';

const SiteSettings = inject('SiteSettings');

const emit = defineEmits(['season-created'])

const props = defineProps({
    content: Object, // Propiedad para recibir información del contenido relacionado
})

const isOpen = ref(false)
const loading = ref(false)
const seasonData = ref({
    name: '',
    description: ''
    // Agrega más campos de datos para la temporada según tus requerimientos
})

const setIsOpen = (value) => {
    clearData()
    isOpen.value = value
}

defineExpose({
    setIsOpen
})

const clearData = () => {
    seasonData.value.name = ''
    // Limpia otros campos de datos de la temporada si los tienes
}

const submitCreateSeason = (e) => {
    e.preventDefault()
    loading.value = true

    // Modifica la lógica para crear la temporada y asóciala al contenido relacionado según tus necesidades
    const data = {
        season: {
            title: seasonData.value.name,
            description: seasonData.value.description
            // Agrega otros campos de datos de la temporada si los tienes
        }
    }


    console.log(props.content)


    ajax.post(`/admin/content-manager/${props.content.id}/seasons`, data)
        .then(response => {
            toast.success('Season created successfully')
            emit('season-created', response)
        })
        .catch(error => {
            toast.error('An error ocurred while creating the season')
            console.log(error)
        })
        .finally(() => {
            loading.value = false
            setIsOpen(false)
        })

    // En este ejemplo, simplemente se emitirá un evento con los datos de la temporada creada
    emit('season-created', data)

    loading.value = false
    setIsOpen(false)
}
</script>
  