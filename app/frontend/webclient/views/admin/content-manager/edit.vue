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

                        <!-- Categories -->
                        <div>
                            <div class="flex items-center justify-between mb-2">
                                <label class="block text-sm font-medium text-white/80">
                                    Categorías
                                </label>
                                <button v-if="content.tmdb_id && SiteSettings.enable_category_auto_assignment"
                                    @click="syncCategoriesFromTmdb"
                                    :disabled="syncingCategories"
                                    class="text-xs px-3 py-1.5 rounded-lg bg-[#00A8E1]/20 hover:bg-[#00A8E1]/30 text-[#00A8E1] transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
                                    <span v-if="syncingCategories">Sincronizando...</span>
                                    <span v-else>Sincronizar de TMDB</span>
                                </button>
                            </div>
                            <div v-if="categoriesLoading" class="text-white/60 text-sm">
                                Cargando categorías...
                            </div>
                            <div v-else class="space-y-2 max-h-48 overflow-y-auto">
                                <label v-for="category in categories" :key="category.id"
                                    class="flex items-center gap-2 p-2 rounded-lg bg-white/5 hover:bg-white/10 cursor-pointer transition-colors">
                                    <input type="checkbox" :value="category.id" v-model="editedData.category_ids"
                                        class="w-4 h-4 rounded border-white/30 bg-white/10 text-[#00A8E1] focus:ring-[#00A8E1] focus:ring-offset-0" />
                                    <span class="text-white/80 text-sm">{{ category.name }}</span>
                                </label>
                            </div>
                            <p v-if="categories.length === 0 && !categoriesLoading" class="text-white/40 text-sm mt-2">
                                No hay categorías disponibles.
                                <a href="/admin/content-manager/categories" class="text-[#00A8E1] hover:underline ml-1">
                                    Crear categorías
                                </a>
                            </p>
                        </div>
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

                <!-- Trailer -->
                <div class="bg-white/5 rounded-xl p-6 ring-1 ring-white/10">
                    <div class="flex items-center justify-between">
                        <div>
                            <h2 class="text-lg font-semibold text-white">
                                Trailer
                            </h2>
                            <p class="text-sm text-white/60 mt-1">
                                {{ hasTrailer ? trailerSummary : 'No trailer configured' }}
                            </p>
                        </div>
                        <div class="flex items-center gap-2 shrink-0">
                            <button v-if="hasTrailer" @click="deleteTrailer"
                                class="text-xs px-3 py-1.5 rounded-lg bg-red-500/20 hover:bg-red-500/30 text-red-400 transition-colors">
                                Delete
                            </button>
                            <CButton @click="trailerModalRef?.setIsOpen(true)">
                                {{ hasTrailer ? 'Edit' : 'Add' }}
                            </CButton>
                        </div>
                    </div>
                </div>
                <CTrailerManagerModal :content-id="content.id" ref="trailerModalRef" @updated="fetchContent" />

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

        <edit-season-modal v-if="(editedData.content_type || content.content_type) === 'TVSHOW'"
            :content-id="contentId" ref="editSeasonModalRef" @season-updated="fetchContent" />

        <!-- Cast / Characters -->
        <div class="mt-8">
            <div class="flex items-center justify-between mb-4">
                <h2 class="text-xl font-semibold text-white">
                    Cast / Characters
                </h2>
                <button v-if="content.tmdb_id && SiteSettings.enable_metadata_recommendation"
                    @click="syncCastFromTmdb"
                    :disabled="syncingCast"
                    class="text-xs px-3 py-1.5 rounded-lg bg-[#00A8E1]/20 hover:bg-[#00A8E1]/30 text-[#00A8E1] transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
                    <span v-if="syncingCast">Syncing...</span>
                    <span v-else>Sync from TMDB</span>
                </button>
            </div>

            <div v-if="content.cast_members?.length" class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-3">
                <div v-for="cm in content.cast_members" :key="cm.id"
                    class="bg-white/5 rounded-lg p-3 ring-1 ring-white/10 group hover:ring-white/20 transition-all">
                    <div class="aspect-[2/3] rounded-lg overflow-hidden mb-2 bg-white/10">
                        <img v-if="cm.person?.profile_path"
                            :src="`https://image.tmdb.org/t/p/w185${cm.person.profile_path}`"
                            :alt="cm.person?.name"
                            class="w-full h-full object-cover"
                            loading="lazy" />
                        <div v-else class="w-full h-full flex items-center justify-center text-white/30">
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/>
                                <circle cx="12" cy="7" r="4"/>
                            </svg>
                        </div>
                    </div>
                    <p class="text-xs font-semibold text-white truncate">{{ cm.person?.name }}</p>
                    <p class="text-[10px] text-white/50 truncate">as {{ cm.character_name }}</p>
                    <button @click="removeCastMember(cm.id)"
                        class="mt-1 text-[10px] text-red-400 hover:text-red-300 opacity-0 group-hover:opacity-100 transition-opacity">
                        Remove
                    </button>
                </div>
            </div>

            <div v-else class="text-center py-8 bg-white/5 rounded-xl ring-1 ring-white/10">
                <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="mx-auto mb-3 text-white/30">
                    <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
                    <circle cx="9" cy="7" r="4"/>
                    <path d="M23 21v-2a4 4 0 0 0-3-3.87"/>
                    <path d="M16 3.13a4 4 0 0 1 0 7.75"/>
                </svg>
                <p class="text-sm text-white/40">
                    {{ content.tmdb_id ? 'No cast imported yet. Click "Sync from TMDB" to import.' : 'No TMDB ID available. Set a TMDB ID to sync cast.' }}
                </p>
            </div>
        </div>
    </div>
</template>

<script setup>
import { Trash2Icon, PlusIcon, EditIcon } from 'lucide-vue-next';
import { onMounted, ref, inject } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { toast } from 'vue3-toastify';
import { computed } from 'vue';
import addSeasonModal from '../../../components/modals/add-season.modal.vue';
import editSeasonModal from '../../../components/modals/edit-season.modal.vue';
import draggable from 'vuedraggable';
import { ajax } from '../../../lib/Ajax';
import CVideoableManager from "@/components/CVideoableManager";
import CTrailerManagerModal from "../../../components/modals/trailer-manager.modal";

const SiteSettings = inject('SiteSettings');
const i18n = inject('I18n');

const route = useRoute();
const router = useRouter();
const contentId = route.params.id;
const loading = ref(true);
const content = ref({});
const addSeasonModalRef = ref();
const editSeasonModalRef = ref();
const trailerModalRef = ref();
const reorderingSeasons = ref(false);

const hasTrailer = computed(() => {
    return content.value.trailer_url || (content.value.trailer_video_sources?.length > 0);
});

const trailerSummary = computed(() => {
    if (content.value.trailer_video_sources?.length > 0) {
        const vs = content.value.trailer_video_sources[0];
        return `${vs.format?.toUpperCase() || 'Video'} · ${vs.quality || ''}`;
    }
    if (content.value.trailer_url) {
        return 'External URL';
    }
    return '';
});
const contentTypes = ref([
    { value: 'MOVIE', label: 'Película' },
    { value: 'TVSHOW', label: 'Serie' }
]);
const loadingButton = ref(false);
const categories = ref([]);
const categoriesLoading = ref(false);
const syncingCategories = ref(false);
const syncingCast = ref(false);

const fetchContent = async () => {
    try {
        const response = await ajax.get(`/admin/content-manager/${contentId}.json`);
        content.value = response.data.data;
        editedData.value = Object.fromEntries(Object.entries(content.value).filter(([key, value]) => !['banner', 'cover'].includes(key)));
        // Initialize category_ids from content
        editedData.value.category_ids = content.value.categories?.map(c => c.id) || [];
    } catch (error) {
        console.log(error);
        toast.error('Error al cargar el contenido');
    } finally {
        loading.value = false;
    }
};

const fetchCategories = async () => {
    categoriesLoading.value = true;
    try {
        const response = await ajax.get('/admin/categories.json');
        categories.value = response.data.data || [];
    } catch (error) {
        console.error('Failed to fetch categories:', error);
    } finally {
        categoriesLoading.value = false;
    }
};

const syncCategoriesFromTmdb = async () => {
    if (!confirm('This will sync categories from TMDB. Continue?')) {
        return;
    }

    syncingCategories.value = true;
    try {
        const response = await ajax.post(`/admin/content-manager/${contentId}/sync-categories.json`);
        toast.success(`Categories synced successfully: ${response.data.assigned_count} categories assigned`);
        await fetchContent();
    } catch (error) {
        console.error('Failed to sync categories from TMDB:', error);
        toast.error('Failed to sync categories from TMDB. Check console for details.');
    } finally {
        syncingCategories.value = false;
    }
};

const syncCastFromTmdb = async () => {
    if (!confirm('This will sync cast from TMDB. Continue?')) {
        return;
    }

    syncingCast.value = true;
    try {
        const response = await ajax.post(`/admin/content-manager/${contentId}/sync-cast.json`);
        toast.success(`Cast synced: ${response.data.assigned_count} members imported`);
        await fetchContent();
    } catch (error) {
        console.error('Failed to sync cast from TMDB:', error);
        toast.error('Failed to sync cast from TMDB.');
    } finally {
        syncingCast.value = false;
    }
};

const removeCastMember = async (castMemberId) => {
    if (!confirm('Remove this cast member?')) {
        return;
    }

    try {
        await ajax.delete(`/admin/content-manager/${contentId}/cast-members/${castMemberId}.json`);
        toast.success('Cast member removed');
        await fetchContent();
    } catch (error) {
        toast.error('Failed to remove cast member');
    }
};

const deleteTrailer = async () => {
    if (!confirm('Delete this trailer?')) {
        return;
    }

    try {
        // Delete trailer video sources
        if (content.value.trailer_video_sources?.length > 0) {
            for (const vs of content.value.trailer_video_sources) {
                await ajax.delete(`/admin/video_sources/${vs.id}.json`);
            }
        }
        // Clear trailer_url if set
        if (content.value.trailer_url) {
            const formData = new FormData();
            formData.append('content[trailer_url]', '');
            await ajax.put(`/admin/content-manager/${contentId}.json`, formData);
        }
        toast.success('Trailer deleted');
        await fetchContent();
    } catch (error) {
        toast.error('Failed to delete trailer');
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
            // Handle category_ids array
            if (key === 'category_ids' && Array.isArray(value)) {
                value.forEach(id => {
                    formData.append(`content[category_ids][]`, id);
                });
            } else {
                formData.append(`content[${key}]`, value);
            }
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
    editSeasonModalRef.value.setIsOpen(true, season);
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
        await ajax.delete(`/admin/content-manager/${contentId}/seasons/${season.id}.json`);
        toast.success('Temporada eliminada');
        await fetchContent();
    } catch (error) {
        console.log(error);
        toast.error('Error al eliminar la temporada');
    }
};

onMounted(() => {
    fetchContent();
    fetchCategories();
});
</script>
