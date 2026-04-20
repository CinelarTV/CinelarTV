<template>
    <div v-if="loading" class="flex items-center justify-center min-h-[400px]">
        <div class="flex flex-col items-center gap-3">
            <div class="animate-spin rounded-full h-12 w-12 border-2 border-white/30 border-t-[#00A8E1]"></div>
            <p class="text-white/60 text-sm font-medium">Cargando...</p>
        </div>
    </div>

    <div v-else class="max-w-5xl mx-auto px-4 sm:px-6 md:px-8 py-8">
        <!-- Header -->
        <div class="mb-8">
            <div class="flex items-center gap-4 mb-2">
                <button @click="router.back()" class="p-2 rounded-lg bg-white/5 hover:bg-white/10 transition-colors">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none"
                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                        class="w-5 h-5">
                        <polyline points="15 18 9 12 15 6" />
                    </svg>
                </button>
                <div>
                    <h1 class="text-2xl md:text-3xl font-bold text-white">
                        Editar contenido
                    </h1>
                    <p class="text-sm text-white/60 mt-1">
                        {{ editedData.title || content.title }}
                    </p>
                </div>
            </div>
        </div>

        <!-- Main Form -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <!-- Left Column - Basic Info -->
            <div class="lg:col-span-2 space-y-6">
                <!-- Basic Information -->
                <div class="bg-white/5 rounded-xl p-6 ring-1 ring-white/10">
                    <h2 class="text-lg font-semibold text-white mb-4">
                        Información básica
                    </h2>
                    <div class="space-y-4">
                        <c-input v-model="editedData.title" placeholder="Título" label="Título" />

                        <c-select :options="contentTypes" v-model="editedData.content_type" label="Tipo de contenido" />

                        <c-textarea placeholder="Descripción" v-model="editedData.description" label="Descripción"
                            :rows="4" />

                        <c-input type="number" placeholder="Año" v-model="editedData.year" label="Año" />
                    </div>
                </div>

                <!-- Images -->
                <div class="bg-white/5 rounded-xl p-6 ring-1 ring-white/10">
                    <h2 class="text-lg font-semibold text-white mb-4">
                        Imágenes
                    </h2>
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-6">
                        <div>
                            <label class="block text-sm font-medium text-white/80 mb-2">
                                Cover (2:3)
                            </label>
                            <c-image-upload v-model="editedData.cover" :modelValue="editedData.cover || content.cover"
                                aspect-ratio="2:3" />
                        </div>
                        <div>
                            <label class="block text-sm font-medium text-white/80 mb-2">
                                Banner (16:9)
                            </label>
                            <c-image-upload v-model="editedData.banner"
                                :modelValue="editedData.banner || content.banner" aspect-ratio="16:9" />
                        </div>
                    </div>
                </div>

                <!-- Video Sources - Only for Movies -->
                <CVideoableManager v-if="(editedData.content_type || content.content_type) !== 'TVSHOW'" :content-id="content.id" :season-id="seasonId" :episode-id="episodeId"
                    :initial-video-sources="content.video_sources" @video-source-added="fetchContent" />
            </div>

            <!-- Right Column - Settings -->
            <div class="space-y-6">
                <!-- Status -->
                <div class="bg-white/5 rounded-xl p-6 ring-1 ring-white/10">
                    <h2 class="text-lg font-semibold text-white mb-4">
                        Estado
                    </h2>
                    <div class="space-y-4">
                        <div class="flex items-center justify-between">
                            <span class="text-sm text-white/80">
                                Disponible para usuarios
                            </span>
                            <button @click="editedData.available = !editedData.available"
                                :class="editedData.available ? 'bg-[#00A8E1]' : 'bg-white/20'"
                                class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-[#00A8E1] focus:ring-offset-2 focus:ring-offset-[#1a1a1a]">
                                <span :class="editedData.available ? 'translate-x-6' : 'translate-x-1'"
                                    class="inline-block h-4 w-4 transform rounded-full bg-white transition-transform" />
                            </button>
                        </div>

                        <div
                            class="flex items-center justify-between p-3 rounded-lg bg-yellow-500/10 border border-yellow-500/20">
                            <div>
                                <p class="text-xs font-bold text-white uppercase tracking-wider">Premium</p>
                                <p class="text-[10px] text-white/40">Solo suscriptores</p>
                            </div>
                            <button @click="editedData.premium = !editedData.premium"
                                :class="editedData.premium ? 'bg-yellow-500' : 'bg-white/20'"
                                class="relative inline-flex h-5 w-9 items-center rounded-full transition-colors focus:outline-none">
                                <span :class="editedData.premium ? 'translate-x-5' : 'translate-x-1'"
                                    class="inline-block h-3 w-3 transform rounded-full bg-white transition-transform" />
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Actions -->
                <div class="bg-white/5 rounded-xl p-6 ring-1 ring-white/10 space-y-3">
                    <h2 class="text-lg font-semibold text-white mb-4">
                        Acciones
                    </h2>
                    <c-button @click="saveContent" :loading="loadingButton" class="w-full justify-center">
                        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none"
                            stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                            class="w-4 h-4 mr-2">
                            <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z" />
                            <polyline points="17 21 17 13 7 13 7 21" />
                            <polyline points="7 3 7 8 15 8" />
                        </svg>
                        Guardar cambios
                    </c-button>

                    <c-button
                        class="w-full justify-center bg-red-500/20 hover:bg-red-500/30 text-red-400 border-red-500/30"
                        @click="deleteContent">
                        <Trash2Icon class="w-4 h-4 mr-2" />
                        Eliminar contenido
                    </c-button>
                </div>
            </div>
        </div>

        <!-- Seasons Management (TV Shows) -->
        <div v-if="(editedData.content_type || content.content_type) === 'TVSHOW'" class="mt-8">
            <div class="flex items-center justify-between mb-4">
                <h2 class="text-xl font-semibold text-white">
                    Temporadas
                </h2>
                <c-button @click="addSeason">
                    <PlusIcon class="w-4 h-4 mr-2" />
                    Agregar temporada
                </c-button>
            </div>

            <draggable tag="div" v-model="content.seasons" class="space-y-3" :group="seasonGroup" handle=".handle"
                ghost-class="opacity-50" @start="reorderingSeasons = true" @end="reorderingSeasons = false">
                <template #item="{ element }">
                    <div
                        class="bg-white/5 rounded-lg p-4 ring-1 ring-white/10 flex items-center gap-4 group hover:ring-white/20 transition-all">
                        <c-icon-button class="handle cursor-move text-white/40 hover:text-white/60"
                            icon="grip-vertical" />

                        <div class="flex-1">
                            <h3 class="text-base font-semibold text-white">
                                {{ element.title }}
                            </h3>
                            <p class="text-sm text-white/60 mt-0.5">
                                {{ element.episodes_count || 0 }} episodios
                            </p>
                        </div>

                        <div class="flex items-center gap-2 opacity-60 group-hover:opacity-100 transition-opacity">
                            <c-button @click="editSeason(element)" size="sm" variant="ghost">
                                <EditIcon class="w-4 h-4" />
                            </c-button>
                            <c-button @click="editSeasonEpisodes(element.id)" size="sm" variant="ghost">
                                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24"
                                    fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"
                                    stroke-linejoin="round" class="w-4 h-4">
                                    <path d="M12 20h9" />
                                    <path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5z" />
                                </svg>
                                <span class="hidden sm:inline ml-1">Episodios</span>
                            </c-button>
                            <c-button class="text-red-400 hover:text-red-300" @click="deleteSeason(element)" size="sm"
                                variant="ghost">
                                <Trash2Icon class="w-4 h-4" />
                            </c-button>
                        </div>
                    </div>
                </template>
            </draggable>
        </div>

        <add-season-modal v-if="(editedData.content_type || content.content_type) === 'TVSHOW'" :content="content"
            ref="addSeasonModalRef" @season-created="fetchContent" />
    </div>
</template>

<script setup>
import { Trash2Icon, PlusIcon, EditIcon } from 'lucide-vue-next';
import { onMounted, ref, inject } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { toast } from 'vue3-toastify';
import addSeasonModal from '../../../components/modals/add-season.modal.vue';
import draggable from 'vuedraggable';
import { ajax } from '../../../lib/Ajax';
import CVideoableManager from "@/components/CVideoableManager";

const SiteSettings = inject('SiteSettings');
const i18n = inject('I18n');

const route = useRoute();
const router = useRouter();
const contentId = route.params.id;
const loading = ref(true);
const content = ref({});
const addSeasonModalRef = ref();
const reorderingSeasons = ref(false);
const contentTypes = ref([
    { value: 'MOVIE', label: 'Película' },
    { value: 'TVSHOW', label: 'Serie' }
]);
const loadingButton = ref(false);

const fetchContent = async () => {
    try {
        const response = await ajax.get(`/admin/content-manager/${contentId}.json`);
        content.value = response.data.data;
        editedData.value = Object.fromEntries(Object.entries(content.value).filter(([key, value]) => !['banner', 'cover'].includes(key)));
    } catch (error) {
        console.log(error);
        toast.error('Error al cargar el contenido');
    } finally {
        loading.value = false;
    }
};

const editedData = ref({});

const seasonGroup = {
    name: 'seasons',
    put: true,
    pull: true
};

import { watch } from 'vue';
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
        toast.success('Orden de temporadas actualizado');
        await fetchContent();
    } catch (error) {
        console.log(error);
        toast.error('Error al reordenar las temporadas');
    }
};

const saveContent = async (e) => {
    e.preventDefault();
    loadingButton.value = true;
    try {
        const formData = new FormData();
        Object.entries(editedData.value).forEach(([key, value]) => {
            if (['id', 'created_at', 'updated_at', 'seasons'].includes(key)) {
                return;
            }
            // Only skip undefined/null — allow false/empty strings/0 to be sent
            if (value === undefined || value === null) {
                return;
            }
            formData.append(`content[${key}]`, value);
        });

        if (formData.entries().next().done) {
            toast.info('No se ha modificado ningún dato.');
            loadingButton.value = false;
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
        if (!confirm('¿Estás seguro de que quieres eliminar este contenido?')) {
            return;
        }

        await ajax.delete(`/admin/content-manager/${contentId}.json`);
        router.push({
            name: 'admin.content.manager.all'
        });
        toast.success('Contenido eliminado');
    } catch (error) {
        console.log(error);
        toast.error('Error al eliminar el contenido');
    }
};

const addSeason = () => {
    addSeasonModalRef.value.setIsOpen(true);
};

const editSeason = (season) => {
    // TODO: Implement season editing
    toast.info('Edición de temporada');
};

const editSeasonEpisodes = (id) => {
    router.push({
        path: `/admin/content-manager/${contentId}/seasons/${id}/episodes`
    });
};

const deleteSeason = async (season) => {
    if (!confirm(`¿Eliminar "${season.title}"? Esta acción no se puede deshacer.`)) {
        return;
    }

    try {
        await ajax.delete(`/admin/content-manager/seasons/${season.id}.json`);
        toast.success('Temporada eliminada');
        await fetchContent();
    } catch (error) {
        console.log(error);
        toast.error('Error al eliminar la temporada');
    }
};

onMounted(() => {
    fetchContent();
});
</script>
