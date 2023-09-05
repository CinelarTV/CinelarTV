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


                            <div class="mt-4">
                                <!-- Lista de episodios o formulario de edición -->
                                <!-- Aquí puedes mostrar la lista de episodios existentes o un formulario para editar episodios -->
                                <!-- Puedes utilizar v-for para iterar sobre la lista de episodios -->
                                <!-- Ejemplo: -->
                                <!-- <div v-for="episode in episodes" :key="episode.id">
               ... Mostrar detalles del episodio (título, descripción, etc.)
               ... Agregar botones para editar o eliminar episodio
             </div> -->

                                <!-- Formulario para agregar un nuevo episodio -->
                                <form @submit="addEpisode">
                                    <!-- Campos para ingresar detalles del episodio (título, descripción, etc.) -->
                                    <!-- Ejemplo: -->
                                    <!-- <div class="mb-4">
                 <label for="title" class="block text-sm font-medium">Title</label>
                 <input v-model="newEpisode.title" type="text" id="title" name="title" />
             </div>
             ... Agregar más campos para otros detalles del episodio ... -->

                                    <!-- Botón para agregar el episodio -->
                                    <div class="text-center">
                                        <button type="submit"
                                            class="bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600">
                                            Add Episode
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
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'
import { ref, defineProps, defineEmits } from 'vue';

const isOpen = ref(false)
const loading = ref(true)

const props = defineProps({
    content: Object, // Propiedad para recibir información del contenido relacionado
})


const setIsOpen = (value) => {
    isOpen.value = value
}

defineExpose({
    setIsOpen
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
</script>
