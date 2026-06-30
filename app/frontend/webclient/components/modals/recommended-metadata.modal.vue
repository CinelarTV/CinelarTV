<template>
    <TransitionRoot appear :show="isOpen" as="template">
        <Dialog as="div" @close="handleClose" class="relative z-50">
            <!-- Backdrop -->
            <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0" enter-to="opacity-100"
                leave="duration-200 ease-in" leave-from="opacity-100" leave-to="opacity-0">
                <div class="fixed inset-0 bg-black/60 backdrop-blur-sm" />
            </TransitionChild>

            <!-- Modal container -->
            <div class="fixed inset-0 flex items-center justify-center p-4 z-[103]">
                <TransitionChild as="template" enter="duration-300 ease-out"
                    enter-from="opacity-0 scale-95 translate-y-2" enter-to="opacity-100 scale-100 translate-y-0"
                    leave="duration-200 ease-in" leave-from="opacity-100 scale-100 translate-y-0"
                    leave-to="opacity-0 scale-95 translate-y-2">
                    <DialogPanel
                        class="w-full max-w-2xl max-h-[90vh] flex flex-col rounded-2xl overflow-hidden shadow-2xl ring-1 ring-[var(--c-primary-400)] bg-[var(--c-primary-600)]"
                        @click.stop>
                        <!-- Header -->
                        <div
                            class="bg-[var(--c-primary-color)] px-8 py-6 text-center border-b border-[var(--c-primary-200)] relative">
                            <button @click="handleClose" class="absolute right-4 top-4 text-[var(--c-primary-100)] hover:text-white transition-colors">
                                <XIcon :size="24" />
                            </button>
                            <DialogTitle as="h2"
                                class="text-xl font-semibold tracking-tight text-[var(--c-body-text-color)]">
                                <SparklesIcon :size="20" class="inline-block mr-2 -mt-0.5 text-yellow-500" />
                                Recommended Metadata
                            </DialogTitle>
                            <p class="mt-1 text-sm text-[var(--c-primary-100)]">
                                Select the best match for your content
                            </p>
                        </div>

                        <!-- Content grid (Scrollable) -->
                        <div class="px-6 py-6 overflow-y-auto flex-1 custom-scrollbar">
                            <!-- Loading state -->
                            <div v-if="!props.content?.data?.results?.length" class="text-center py-12">
                                <Loader2Icon :size="48" class="animate-spin mx-auto mb-4 text-[var(--c-tertiary-color)]" />
                                <p class="text-sm text-[var(--c-primary-100)]">
                                    Buscando las mejores recomendaciones...
                                </p>
                            </div>

                            <!-- Results grid -->
                            <div v-else class="grid grid-cols-2 sm:grid-cols-3 gap-4">
                                <button v-for="item in props.content.data.results" :key="item.table.id" type="button"
                                    @click="selectContent(item.table)"
                                    class="group relative rounded-xl overflow-hidden shadow-lg ring-2 ring-transparent hover:ring-[var(--c-tertiary-color)] transition-all duration-300 hover:scale-[1.02] hover:shadow-2xl focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--c-tertiary-color)] bg-black/20">
                                    <!-- Poster image -->
                                    <div class="aspect-[2/3] overflow-hidden">
                                        <img :src="`https://image.tmdb.org/t/p/w342${item.table.poster_path || item.table.profile_path}`"
                                            :alt="item.table.name || item.table.title || item.table.original_name"
                                            class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500"
                                            loading="lazy" />
                                    </div>

                                    <!-- Overlay on hover/always on bottom -->
                                    <div
                                        class="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black via-black/60 to-transparent p-3 pt-8 pb-3">
                                        <p class="text-xs font-bold text-white line-clamp-2 leading-tight">
                                            {{ item.table.name || item.table.title || item.table.original_name }}
                                        </p>
                                        <div class="flex items-center gap-1.5 mt-1.5 opacity-80">
                                            <span class="text-[10px] text-gray-300 uppercase tracking-wider font-bold">
                                                {{ item.table.media_type || item.table.type }}
                                            </span>
                                            <span v-if="item.table.release_date || item.table.first_air_date"
                                                class="text-[10px] text-gray-300">
                                                •
                                            </span>
                                            <span v-if="item.table.release_date || item.table.first_air_date"
                                                class="text-[10px] text-gray-300">
                                                {{ (item.table.release_date || item.table.first_air_date)?.substring(0,
                                                    4) }}
                                            </span>
                                        </div>
                                    </div>

                                    <!-- Selection indicator -->
                                    <div
                                        class="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                                        <div class="bg-[var(--c-tertiary-color)] rounded-full p-2 scale-50 group-hover:scale-100 transition-transform duration-300">
                                            <CheckIcon :size="24" class="text-white" />
                                        </div>
                                    </div>
                                </button>
                            </div>

                            <!-- No results -->
                            <div v-if="props.content?.data?.results?.length === 0" class="text-center py-12">
                                <SearchIcon :size="48" class="mx-auto mb-4 text-[var(--c-primary-400)]" />
                                <p class="text-sm font-medium text-[var(--c-primary-100)]">
                                    No se encontraron recomendaciones
                                </p>
                                <p class="text-xs text-[var(--c-primary-700)] mt-1">
                                    Intenta con otro término de búsqueda
                                </p>
                            </div>
                        </div>

                        <!-- Footer -->
                        <div v-if="props.content?.data?.results?.length" class="px-6 py-4 bg-black/10 border-t border-[var(--c-primary-200)] text-center">
                            <p class="text-xs text-[var(--c-primary-700)] font-medium">
                                Selecciona un póster para importar automáticamente los metadatos
                            </p>
                        </div>
                    </DialogPanel>
                </TransitionChild>
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
    DialogTitle,
} from '@headlessui/vue'
import {
    SparklesIcon,
    CheckIcon,
    Loader2Icon,
    SearchIcon,
    XIcon,
} from 'lucide-vue-next'

const isOpen = ref(false)

const emit = defineEmits(['selectContent', 'close'])

const props = defineProps({
    content: {
        type: Object,
        required: true
    }
})

const setIsOpen = (value) => {
    isOpen.value = value
}

const handleClose = () => {
    isOpen.value = false
    emit('close')
}

// Cuando se selecciona un contenido, se cierra el modal y se envía el contenido seleccionado
const selectContent = (content) => {
    // Evitar propagación del evento
    event?.stopPropagation()
    isOpen.value = false
    emit('selectContent', content)
    emit('close')
}

defineExpose({
    open() {
        setIsOpen(true)
    }
})
</script>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
    width: 6px;
}

.custom-scrollbar::-webkit-scrollbar-track {
    background: transparent;
}

.custom-scrollbar::-webkit-scrollbar-thumb {
    background: rgba(255, 255, 255, 0.1);
    border-radius: 10px;
}

.custom-scrollbar::-webkit-scrollbar-thumb:hover {
    background: rgba(255, 255, 255, 0.2);
}
</style>
