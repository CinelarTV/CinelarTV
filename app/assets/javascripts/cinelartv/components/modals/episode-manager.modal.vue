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
                            <DialogTitle as="h3" class="text-lg font-medium leading-6 text-[var(--primary-600)]" v-emoji>
                                Manage Episodes 🌟
                            </DialogTitle>


                            <div class="mt-4" v-if="loadingEpisodeList">
                                <div class="flex justify-center">
                                    <c-spinner />
                                </div>

                            </div>

                            <div v-else>
                                {{ episodeList }}

                                <div class="flex">
                                    <c-button class="ml-auto" @click="setIsOpen(false)" icon="x">
                                        Close
                                    </c-button>
                                    <c-button class="ml-2" @click="addEpisode()" icon="plus">
                                        Add
                                    </c-button>
                                </div>
                            </div>

                        </DialogPanel>
                    </TransitionChild>
                </div>
            </div>
        </Dialog>
    </TransitionRoot>
</template>

  
<script setup>
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'
import axios from 'axios';
import { ref, defineProps, defineEmits, onMounted } from 'vue';
import draggable from 'vuedraggable'

const isOpen = ref(false)
const loadingEpisodeList = ref(true)
const episodeList = ref([])
const seasonId = ref(null)

const props = defineProps({
    content: Object
})


const setIsOpen = (value) => {
    isOpen.value = value
    if (isOpen.value) {
        episodeList.value = []
        loadingEpisodeList.value = true
        getEpisodeList()
    }
}

const setSeasonId = (value) => {
    seasonId.value = value
}

defineExpose({
    setIsOpen,
    setSeasonId
})


const newEpisode = ref({
    // Inicializa los campos del nuevo episodio (título, descripción, etc.)
    // Ejemplo: title: '',
});


const addEpisode = () => {
    // Método para agregar un nuevo episodio
    // Puedes enviar una solicitud al servidor para guardar el nuevo episodio
    // Ejemplo: axios.post("/api/episodes", newEpisode.value)
    // Luego, actualiza la lista de episodios o realiza otras acciones necesarias
    // Después de agregar el episodio, puedes limpiar los campos de entrada, si es necesario
    // Ejemplo: newEpisode.value = { title: '', ...otros campos };
};

const getEpisodeList = () => {
    axios.get(`/admin/content-manager/${props.content.id}/seasons/${seasonId.value}/episodes.json`)
        .then((response) => {
            loadingEpisodeList.value = false
            episodeList.value = response.data.data
        })
        .catch((error) => {
            loadingEpisodeList.value = false
            // Muestra un mensaje de error
            // Ejemplo: toast.error(error.response.data.message);
        });
};

</script>
