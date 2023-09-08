<template>
    <div v-if="loading">
        <c-spinner />
    </div>
    <div v-else>
        <div class="panel">
            <div class="panel-header">
                <div class="panel-title">
                    {{ content.title }}
                </div>
            </div>
            <div class="panel-body">
                <div class="edit-content" :data-content-id="$route.params.id">

                    <form @submit="saveContent">
                        <c-input :modelValue="content.title" @update:text="value => editedData.title = value"
                            placeholder="Title" />

                        <c-select :options="contentTypes" :modelValue="editedData.content_type"
                            @update:modelValue="value => editedData.content_type = value"
                            class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />

                        <c-textarea placeholder="Description" :modelValue="content.description"
                            @update:modelValue="value => editedData.description = value" />

                        <c-image-upload placeholder="Cover" :modelValue="content.cover"
                            @update:modelValue="value => editedData.cover = value" />

                        <c-image-upload placeholder="Banner" :value="content.banner"
                            @update:modelValue="value => editedData.banner = value" />

                        <c-input type="number" placeholder="Year" :value="content.year"
                            @update:modelValue="value => editedData.year = value" />

                        <template v-if="content.content_type === 'MOVIE' && SiteSettings.allow_video_direct_link">
                            <c-input placeholder="Paste Video Link" :value="content.url"
                                @update:modelValue="value => editedData.url = value" />
                        </template>

                        <input type="checkbox" class="ml-auto" :checked="content.available"
                            @change="e => editedData.available = e.target.checked" />



                        <c-button type="submit" :loading="loadingButton" :icon="SaveIcon">
                            Save
                        </c-button>
                    </form>

                    <c-button class="bg-red-500" @click="deleteContent" :icon="Trash2Icon">
                        Delete
                    </c-button>
                </div>

                <!-- Mostrar lista de episodios y temporadas si es una serie (TVSHOW) -->
                <div v-if="content.content_type === 'TVSHOW'">
                    <div class="panel-header flex">
                        <h2 class="text-xl font-bold mt-4">
                            Contenido
                        </h2>
                        <c-button class="ml-auto" @click="addSeason">
                            <PlusIcon class="icon" :size="18" />
                            Add Season
                        </c-button>
                    </div>

                    <draggable tag="div" v-model="content.seasons" class="season-list" :group="seasonGroup" handle=".handle"
                        ghost-class="opacity-50" @start="reorderingSeasons = true" @end="reorderingSeasons = false">
                        <template #item="{ element, index }">
                            <div class="season-container">
                                <c-icon-button class="handle" icon="grip-vertical" />
                                <div class="season-header">
                                    <h3 class="season-title">
                                        {{ element.title }}
                                    </h3>
                                </div>
                                <div class="season-actions">
                                    <c-button @click="editSeason(element)">
                                        <EditIcon class="icon" :size="18" />
                                        Edit
                                    </c-button>
                                    <c-button @click="editSeasonEpisodes(element.id)">
                                        <EditIcon class="icon" :size="18" />
                                        Manage Episodes
                                    </c-button>
                                    <c-button class="ml-2" @click="deleteSeason(element)">
                                        <Trash2Icon class="icon" :size="18" />
                                        Delete
                                    </c-button>


                                </div>

                            </div>
                        </template>

                    </draggable>
                </div>

            </div>
        </div>
        <add-season-modal v-if="content.content_type === 'TVSHOW'" :content="content" ref="addSeasonModalRef"
            @season-created="fetchContent" />
        <EpisodeManagerModal v-if="content.content_type === 'TVSHOW'" :content="content" ref="episodeManagerModalRef" :seasonId="selectedSeason" />
    </div>
</template>
  
<script setup>
import { Trash2Icon } from 'lucide-vue-next';
import { SaveIcon, PlusIcon } from 'lucide-vue-next';
import { onMounted, ref, inject, computed, watch } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { toast } from 'vue3-toastify';
import addSeasonModal from '../../../components/modals/add-season.modal.vue';
import EpisodeManagerModal from '../../../components/modals/episode-manager.modal.vue';
import draggable from 'vuedraggable';
import { ajax } from '../../../lib/axios-setup';

const SiteSettings = inject('SiteSettings');

const route = useRoute();
const router = useRouter();
const contentId = route.params.id;
const loading = ref(true);
const content = ref({});
const addSeasonModalRef = ref();
const episodeManagerModalRef = ref();
const reorderingSeasons = ref(false);
const contentTypes = ref([
    { value: 'MOVIE', label: 'Movie' },
    { value: 'TVSHOW', label: 'Serie' }
]);
const loadingButton = ref(false);
const selectedSeason = ref('');

const fetchContent = async () => {
    try {
        const response = await ajax.get(`/admin/content-manager/${contentId}.json`);
        content.value = response.data.data;
        editedData.value = { ...content.value };
    } catch (error) {
        console.log(error);
    } finally {
        loading.value = false;
    }
};

const editedData = ref({});

watch(reorderingSeasons, async (value) => {
    if (value === false) {
        await saveSeasonsOrder();
    }
});

const saveSeasonsOrder = async () => {
    try {
        const response = await ajax.put(`/admin/content-manager/${contentId}/reorder-seasons.json`, {
            season_order: content.value.seasons.map((season) => season.id)
        });
        toast.success('Orden de temporadas guardado con éxito.');
        await fetchContent();
    } catch (error) {
        console.log(error);
        toast.error('Error al guardar el orden de temporadas: ' + error.error);
    }
};

const saveContent = async (e) => {
    e.preventDefault();
    loadingButton.value = true;
    try {
        const formData = new FormData();
        Object.entries(editedData.value).forEach(([key, value]) => {
            if (['id', 'created_at', 'updated_at'].includes(key)) {
                return;
            }
            formData.append(`content[${key}]`, value);
        });

        // If formData is empty, don't send the request
        if (formData.entries().next().done) {
            toast.info('No se ha modificado ningún dato.');
            return;
        }

        const response = await ajax.put(`/admin/content-manager/${contentId}.json`, formData);
        toast.success('Contenido guardado con éxito.');

        await fetchContent();
    } catch (error) {
        console.log(error);
        toast.error('Error al guardar el contenido: ' + error.error);
    } finally {
        loadingButton.value = false;
    }
};

const deleteContent = async () => {
    try {
        const response = await ajax.delete(`/admin/content-manager/${contentId}.json`);
        router.push({
            name: 'admin.content.manager.all'
        });
    } catch (error) {
        console.log(error);
    }
};

const addSeason = () => {
    addSeasonModalRef.value.setIsOpen(true);
};

const editSeasonEpisodes = (id) => {
    episodeManagerModalRef.value.setSeasonId(id);
    episodeManagerModalRef.value.setIsOpen(true);
};

onMounted(() => {
    fetchContent();
    console.log(episodeManagerModalRef);
});
</script>
  