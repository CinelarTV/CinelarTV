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
                            <c-input placeholder="Paste Video Link" :value="content.video_link"
                                @update:modelValue="value => editedData.video_link = value" />
                        </template>


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

                    <div v-for="season in content.seasons" :key="season.id">
                        <div class="season-header flex items-center">
                            <h3 class="text-lg font-semibold">{{ season.title }}</h3>
                            <c-button @click="editSeason(season)">
                                <EditIcon class="icon" :size="18" />
                                Edit
                            </c-button>
                            <c-button @click="editSeasonEpisodes(season)">
                                <EditIcon class="icon" :size="18" />
                                Manage Episodes
                            </c-button>
                            <c-button class="ml-2" @click="deleteSeason(season)">
                                <Trash2Icon class="icon" :size="18" />
                                Delete
                            </c-button>
                        </div>
                        <ul>
                            <li v-for="episode in season.episodes" :key="episode.id">
                                {{ episode.title }}
                            </li>
                        </ul>
                    </div>
                </div>

            </div>
        </div>
        <add-season-modal v-if="content.content_type === 'TVSHOW'" :content="content" ref="addSeasonModalRef"
            @season-created="fetchContent" />
        <EpisodeManagerModal v-if="content.content_type === 'TVSHOW'" :content="content"
            ref="episodeManagerModalRef" />
    </div>
</template>
  
<script setup>
import { Trash2Icon } from 'lucide-vue-next';
import { SaveIcon, PlusIcon } from 'lucide-vue-next';
import { onMounted, ref, inject } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { toast } from 'vue3-toastify';
import addSeasonModal from '../../../components/modals/add-season.modal.vue';
import EpisodeManagerModal from '../../../components/modals/episode-manager.modal.vue';

const SiteSettings = inject('SiteSettings');

const route = useRoute();
const router = useRouter();
const contentId = route.params.id;
const loading = ref(true);
const content = ref({});
const addSeasonModalRef = ref();
const episodeManagerModalRef = ref();
const contentTypes = ref([
    { value: 'MOVIE', label: 'Movie' },
    { value: 'TVSHOW', label: 'Serie' }
]);
const loadingButton = ref(false);

const fetchContent = async () => {
    try {
        const response = await axios.get(`/admin/content-manager/${contentId}.json`);
        content.value = response.data.data;
        editedData.value = { ...content.value };
    } catch (error) {
        console.log(error);
    } finally {
        loading.value = false;
    }
};

const editedData = ref({});

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

        const response = await axios.put(`/admin/content-manager/${contentId}.json`, formData);
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
        const response = await axios.delete(`/admin/content-manager/${contentId}.json`);
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

const editSeasonEpisodes = () => {
    episodeManagerModalRef.value.setIsOpen(true);
};

onMounted(() => {
    fetchContent();
    console.log(episodeManagerModalRef);
});
</script>
  