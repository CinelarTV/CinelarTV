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
                            class="dialog episode-manager w-full max-w-4xl transform overflow-hidden p-4 text-left align-middle shadow-xl transition-all">
                            <DialogTitle as="h3" class="text-lg font-medium leading-6 text-[var(--primary-600)]" v-emoji>
                                Manage Episodes 🌟
                            </DialogTitle>


                            <div class="mt-4" v-if="loadingEpisodeList">
                                <div class="flex justify-center">
                                    <c-spinner />
                                </div>

                            </div>

                            <div v-else>
                                <draggable tag="div" v-model="episodeList" class="episode-manager-list" handle=".handle"
                                    :group="episodeGroup" ghost-class="opacity-50" @start="reorderingEpisodes = true"
                                    @end="reorderingEpisodes = false">
                                    <template #item="{ element, index }">
                                        <div class="editor-episode-container">
                                            <c-icon-button class="handle" icon="grip-vertical" />
                                            <img :src="element.thumbnail" class="episode-thumbnail" />
                                            <div class="episode-header">
                                                <h3 class="episode-title">
                                                    {{ element.title }}
                                                </h3>
                                                <p class="episode-description">
                                                    {{ element.description }}
                                                </p>
                                            </div>
                                            <div class="episode-actions">
                                                <c-button @click="editEpisode(element)">
                                                    <EditIcon class="icon" :size="18" />
                                                    Edit
                                                </c-button>
                                                <c-button class="ml-2" @click="deleteEpisode(element)">
                                                    <Trash2Icon class="icon" :size="18" />
                                                    Delete
                                                </c-button>
                                            </div>
                                        </div>
                                    </template>
                                </draggable>


                                <div class="flex">
                                    <c-button class="ml-auto" @click="setIsOpen(false)" icon="x">
                                        Close
                                    </c-button>
                                    <c-button class="ml-2" @click="createEpisode" icon="plus">
                                        Add
                                    </c-button>
                                </div>
                            </div>

                        </DialogPanel>
                    </TransitionChild>
                </div>
            </div>
        <create-episode-modal ref="episodeModalRef" :season-id="seasonId" @episode-created="getEpisodeList()" :content-id="props.content.id" />
        </Dialog>
    </TransitionRoot>
</template>

  
<script setup>
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'
import { ref, defineProps, defineEmits, onMounted, watch } from 'vue';
import draggable from 'vuedraggable'
import { ajax } from '../../lib/axios-setup';
import { toast } from 'vue3-toastify';
import createEpisodeModal from './create-episode.modal.vue';

const isOpen = ref(false)
const loadingEpisodeList = ref(true)
const episodeList = ref([])
const seasonId = ref(null)
const reorderingEpisodes = ref(false)
const episodeModalRef = ref()

watch(reorderingEpisodes, async (value) => {
    if (value === false) {
        await reorderEpisodes();
    }
});

const props = defineProps({
    content: Object
})



const setIsOpen = async (value) => {
    isOpen.value = value
    if (isOpen.value) {
        episodeList.value = []
        loadingEpisodeList.value = true
        await getEpisodeList()
    }
}

const setSeasonId = (value) => {
    seasonId.value = value
}

defineExpose({
    setIsOpen,
    setSeasonId
})


const createEpisode = () => {
    episodeModalRef.value.setIsOpen(true)
}

const reorderEpisodes = async () => {
    try {
        const response = await ajax.put(`/admin/content-manager/${props.content.id}/seasons/${seasonId.value}/reorder-episodes.json`, {
            episode_order: episodeList.value.map((episode) => episode.id)
        });
        toast.success('Orden de episodios guardado con éxito.');
        await getEpisodeList();
    } catch (error) {
        console.log(error);
        toast.error('Error al guardar el orden de episodios: ' + error.error);
    }
};



const getEpisodeList = async () => {
    try {
        const response = await ajax.get(`/admin/content-manager/${props.content.id}/seasons/${seasonId.value}/episodes.json`);
        loadingEpisodeList.value = false;
        episodeList.value = response.data.data.episodes;
    } catch (error) {
        loadingEpisodeList.value = false;
        // Manejar el error aquí, por ejemplo:
        // toast.error(error.response.data.message);
    }
};


</script>
