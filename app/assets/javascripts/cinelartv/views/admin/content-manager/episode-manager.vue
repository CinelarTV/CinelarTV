<template>
    <div class="mt-4" v-if="loadingEpisodeList">
        <div class="flex justify-center">
            <c-spinner />
        </div>

    </div>
    <div v-else class="mt-4"> 
        <div class="flex">
            
            <c-button @click="backToEditor" icon="chevron-left">
                Regresar
            </c-button>
            <c-button class="ml-auto" @click="createEpisode" icon="plus">
                Add
            </c-button>
        </div>
        <draggable tag="div" v-model="episodeList" class="episode-manager-list" handle=".handle" :group="episodeGroup"
            ghost-class="opacity-50" @start="reorderingEpisodes = true" @end="reorderingEpisodes = false">
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
                        <c-button @click="editEpisode(element)" icon="pencil">
                            Edit
                        </c-button>
                        <c-button class="ml-2" @click="deleteEpisode(element)" icon="trash2">
                            Delete
                        </c-button>
                    </div>
                </div>
            </template>
        </draggable>

        <create-episode-modal ref="episodeModalRef" :season-id="route.params.seasonId" @episode-created="getEpisodeList()"
            :content-id="route.params.contentId" />

    </div>
</template>

<script setup>
import { ref, defineProps, watch, onMounted, inject } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import draggable from 'vuedraggable'
import { toast } from 'vue3-toastify';
import createEpisodeModal from '../../../components/modals/create-episode.modal.vue';
import { ajax } from '../../../lib/Ajax';

const loadingEpisodeList = ref(true)
const episodeList = ref([])
const reorderingEpisodes = ref(false)
const episodeModalRef = ref()

const route = useRoute()
const router = useRouter()
const i18n = inject('I18n')

watch(reorderingEpisodes, async (value) => {
    if (value === false) {
        await reorderEpisodes();
    }
});


onMounted(async () => {
    episodeList.value = []
    loadingEpisodeList.value = true
    await getEpisodeList()
})


const createEpisode = () => {
    episodeModalRef.value.setIsOpen(true)
}

const reorderEpisodes = async () => {
    try {
        const response = await ajax.put(`/admin/content-manager/${route.params.contentId}/seasons/${route.params.seasonId}/reorder-episodes.json`, {
            episode_order: episodeList.value.map((episode) => episode.id)
        });
        toast.success(i18n.t('admin.content_manager.episode_manager.reorder_success'));
        await getEpisodeList();
    } catch (error) {
        console.log(error);
        toast.error(i18n.t('admin.content_manager.episode_manager.reorder_error', { error: error.message }));
    }
};

const backToEditor = () => {
    router.push({
        path: `/admin/content-manager/${route.params.contentId}/edit`
    })
}



const getEpisodeList = async () => {
    try {
        const response = await ajax.get(`/admin/content-manager/${route.params.contentId}/seasons/${route.params.seasonId}/episodes.json`);
        loadingEpisodeList.value = false;
        episodeList.value = response.data.data.episodes;
    } catch (error) {
        loadingEpisodeList.value = false;
        // Manejar el error aquí, por ejemplo:
        // toast.error(error.response.data.message);
    }
};

const deleteEpisode = async (episode) => {
    if(confirm(i18n.t('admin.content_manager.episode_manager.delete_confirm'))) {
        try {
            const response = await ajax.delete(`/admin/content-manager/${route.params.contentId}/seasons/${route.params.seasonId}/episodes/${episode.id}.json`);
            toast.success(i18n.t('admin.content_manager.episode_manager.delete_success'));
            await getEpisodeList();
        } catch (error) {
            console.log(error);
            toast.error(i18n.t('admin.content_manager.episode_manager.delete_error', { error: error.message }));
        }
    }
};


</script>
../../../lib/ajax