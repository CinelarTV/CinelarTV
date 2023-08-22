<template>
    <TransitionRoot appear :show="isOpen" as="template">
        <Dialog as="div" @close="setIsOpen(false)" class="modal">
            <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0" enter-to="opacity-100"
                leave="duration-200 ease-in" leave-from="opacity-100" leave-to="opacity-0">
                <div class="fixed inset-0 bg-black bg-opacity-95 z-[200]" />
            </TransitionChild>

            <div class="fixed inset-0 overflow-y-auto z-[201]">
                <div class="flex min-h-full items-center justify-center p-4 text-center">
                    <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0 scale-95"
                        enter-to="opacity-100 scale-100" leave="duration-200 ease-in" leave-from="opacity-100 scale-100"
                        leave-to="opacity-0 scale-95">
                        <DialogPanel
                            class="dialog create-content w-full max-w-md transform overflow-hidden rounded-2xl p-6 text-left align-middle shadow-xl transition-all">
                            <DialogTitle as="h3" class="text-lg font-medium leading-6 text-[var(--primary-600)]" v-emoji>
                                Recommended Metadata ✨
                            </DialogTitle>

                           <!-- Grid with Recommended Contents -->

                           <div class="grid grid-cols-3 gap-4 mt-6">
                                <template v-for="content in props.content.data.results">
                                    <div class="flex flex-col rounded-lg shadow-lg overflow-hidden cursor-pointer" @click="selectContent(content.table)">
                                        <div class="flex-shrink-0">
                                            <img :src="`https://image.tmdb.org/t/p/w780${content.table.poster_path}`" :alt="content.table.name" class="h-48 w-full object-cover">
                                        </div>
                                        <div class="flex-1 bg-black py-2 flex flex-col justify-center items-center">
                                            <div class="flex-1">
                                                <p class="text-sm font-medium text-center">
                                                    <a :href="`https://themoviedb.org/${content.table.media_type}/${content.table.id}`" class="hover:underline" target="_blank">
                                                        {{ content.table.name || content.table.title || content.table.original_name }}
                                                    </a>
                                                </p>
                                                
                                            </div>
                                        </div>
                                    </div>
                                </template>
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
    Dialog,
    TransitionChild,
    DialogPanel,
    DialogTitle
} from '@headlessui/vue'

const isOpen = ref(false)

const setIsOpen = (value) => {
    isOpen.value = value
}

const emit = defineEmits(['selectContent'])

const props = defineProps({
    content: {
        type: Object,
        required: true
    }
})


defineExpose({
    open() {
        setIsOpen(true)
    }
})

// Cuando se selecciona un contenido, se cierra el modal y se envía el contenido seleccionado
const selectContent = (content) => {
    setIsOpen(false)
    emit('selectContent', content)
}


</script>
  