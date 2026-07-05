<template>
    <TransitionRoot appear :show="isOpen" as="template">
        <Dialog as="div" class="relative z-50" @close="setIsOpen(false)">
            <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0" enter-to="opacity-100"
                leave="duration-200 ease-in" leave-from="opacity-100" leave-to="opacity-0">
                <div class="fixed inset-0 bg-black/60 backdrop-blur-sm" />
            </TransitionChild>

            <div class="fixed inset-0 flex items-center justify-center p-4">
                <TransitionChild as="template" enter="duration-300 ease-out"
                    enter-from="opacity-0 scale-95 translate-y-2" enter-to="opacity-100 scale-100 translate-y-0"
                    leave="duration-200 ease-in" leave-from="opacity-100 scale-100 translate-y-0"
                    leave-to="opacity-0 scale-95 translate-y-2">
                    <DialogPanel
                        class="w-full max-w-lg rounded-2xl overflow-hidden shadow-2xl ring-1 ring-[var(--c-primary-400)] bg-[var(--c-primary-600)]"
                        @click.stop>

                        <!-- Header -->
                        <div
                            class="bg-[var(--c-primary-color)] px-8 pt-8 pb-6 text-center border-b border-[var(--c-primary-200)]">
                            <DialogTitle as="h2"
                                class="text-xl font-semibold tracking-tight text-[var(--c-body-text-color)]">
                                Create New Season
                            </DialogTitle>
                            <p class="mt-1 text-sm text-[var(--c-primary-100)]">
                                Add manually or import from TMDB
                            </p>
                        </div>

                        <!-- Form body -->
                        <div class="px-8 py-6 overflow-y-auto" style="max-height: calc(100vh - 220px);">
                            <form @submit="(e) => { e.preventDefault() }" novalidate>
                                <div class="space-y-4">
                                    <!-- TMDB Import -->
                                    <div v-if="SiteSettings.enable_metadata_recommendation" class="text-center">
                                        <button type="button" @click="searchTmdb" :disabled="loadingTmdb"
                                            class="inline-flex items-center gap-2 rounded-xl border border-[var(--c-primary-300)] bg-[var(--c-primary-200)] px-4 py-2.5 text-sm font-medium text-[var(--c-body-text-color)] transition-all hover:bg-[var(--c-primary-300)] disabled:cursor-not-allowed disabled:opacity-40">
                                            <Loader2 v-if="loadingTmdb" :size="15" class="animate-spin" />
                                            <SparklesIcon v-else :size="15" />
                                            Import all seasons from TMDB
                                        </button>
                                        <p v-if="contentTmdbId" class="mt-1 text-[10px] text-[var(--c-primary-700)]">
                                            Using content TMDB ID: {{ contentTmdbId }}
                                        </p>
                                    </div>

                                    <!-- TMDB Results -->
                                    <div v-if="tmdbResults.length" class="space-y-2">
                                        <div class="flex items-center justify-between">
                                            <p
                                                class="text-xs font-medium text-[var(--c-primary-100)] uppercase tracking-wider">
                                                TMDB Seasons ({{ tmdbResults.length }})
                                            </p>
                                            <button type="button" @click="importAll"
                                                class="text-xs font-medium text-[var(--c-tertiary-color)] hover:underline">
                                                Import all
                                            </button>
                                        </div>
                                        <div class="max-h-64 overflow-y-auto space-y-1 custom-scrollbar">
                                            <div v-for="season in tmdbResults" :key="season.tmdb_id"
                                                class="flex items-center gap-3 p-2 rounded-lg hover:bg-[var(--c-primary-300)] transition-all">
                                                <img v-if="season.thumbnail"
                                                    :src="`https://image.tmdb.org/t/p/w185${season.thumbnail.replace('tmdb://', '/')}`"
                                                    class="w-10 h-14 object-cover rounded" />
                                                <div class="flex-1 min-w-0">
                                                    <p
                                                        class="text-xs font-medium text-[var(--c-body-text-color)] truncate">
                                                        {{ season.title }}
                                                    </p>
                                                    <p v-if="season.air_date"
                                                        class="text-[10px] text-[var(--c-primary-700)]">
                                                        {{ season.air_date }} · {{ season.episode_count }} episodes
                                                    </p>
                                                </div>
                                                <button type="button" @click="importSingle(season)"
                                                    :disabled="importingIds.includes(season.tmdb_id)"
                                                    class="shrink-0 inline-flex items-center gap-1 rounded-lg bg-[var(--c-tertiary-color)] px-3 py-1.5 text-[10px] font-semibold text-white transition-all hover:bg-[var(--c-tertiary-100)] disabled:opacity-40">
                                                    <Loader2 v-if="importingIds.includes(season.tmdb_id)" :size="12"
                                                        class="animate-spin" />
                                                    <PlusIcon v-else :size="12" />
                                                    {{ importingIds.includes(season.tmdb_id) ? 'Adding...' : 'Add' }}
                                                </button>
                                            </div>
                                        </div>
                                    </div>

                                    <div v-if="SiteSettings.enable_metadata_recommendation"
                                        class="relative flex items-center">
                                        <div class="flex-grow border-t border-[var(--c-primary-200)]" />
                                        <span class="mx-3 text-xs text-[var(--c-primary-100)]">or create
                                            manually</span>
                                        <div class="flex-grow border-t border-[var(--c-primary-200)]" />
                                    </div>

                                    <!-- Manual: Title -->
                                    <CFormRow label="Season Title" for="season-title" :error="errors.title">
                                        <CInput v-model="seasonData.title" id="season-title"
                                            placeholder="Season 1" />
                                    </CFormRow>

                                    <!-- Manual: Description -->
                                    <CFormRow label="Description" for="season-description" :error="errors.description">
                                        <CTextarea v-model="seasonData.description" id="season-description"
                                            placeholder="Optional description..." :rows="2" />
                                    </CFormRow>
                                </div>

                                <!-- Error -->
                                <p v-if="generalError" class="mt-4 text-xs font-medium text-center text-rose-400">
                                    {{ generalError }}
                                </p>

                                <!-- Actions -->
                                <div class="mt-6 flex items-center justify-end gap-3">
                                    <button type="button" @click="setIsOpen(false)"
                                        class="inline-flex items-center gap-2 rounded-xl border border-[var(--c-primary-300)] bg-[var(--c-primary-200)] px-4 py-2.5 text-sm font-medium text-[var(--c-body-text-color)] transition-all hover:bg-[var(--c-primary-300)]">
                                        Cancel
                                    </button>
                                    <button type="button" @click="submitCreateSeason"
                                        :disabled="!canSubmit || loading"
                                        class="inline-flex items-center gap-2 rounded-xl bg-[var(--c-tertiary-color)] px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-all hover:bg-[var(--c-tertiary-100)] disabled:cursor-not-allowed disabled:opacity-40">
                                        <Loader2 v-if="loading" :size="15" class="animate-spin" />
                                        <CheckIcon v-else :size="15" />
                                        Create Season
                                    </button>
                                </div>
                            </form>
                        </div>

                    </DialogPanel>
                </TransitionChild>
            </div>
        </Dialog>
    </TransitionRoot>
</template>

<script setup>
import { ref, computed, inject } from 'vue'
import {
    Dialog,
    DialogPanel,
    DialogTitle,
    TransitionChild,
    TransitionRoot,
} from '@headlessui/vue'
import {
    CheckIcon,
    SparklesIcon,
    Loader2,
    PlusIcon,
} from 'lucide-vue-next'
import CInput from '../forms/c-input.vue'
import CTextarea from '../forms/c-textarea.vue'
import CFormRow from '../forms/CFormRow.tsx'
import { ajax } from '../../lib/Ajax'

const SiteSettings = inject('SiteSettings')

const emit = defineEmits(['season-created'])

const props = defineProps({
    content: Object,
})

const isOpen = ref(false)
const loading = ref(false)
const loadingTmdb = ref(false)
const generalError = ref('')
const errors = ref({})
const tmdbResults = ref([])
const importingIds = ref([])

const seasonData = ref({
    title: '',
    description: '',
})

const contentTmdbId = computed(() => props.content?.tmdb_id || null)

const canSubmit = computed(() => {
    return seasonData.value.title.trim().length >= 1 && !loading.value
})

const setIsOpen = (value) => {
    clearData()
    isOpen.value = value
}

defineExpose({
    setIsOpen,
})

const clearData = () => {
    seasonData.value = { title: '', description: '' }
    tmdbResults.value = []
    importingIds.value = []
    errors.value = {}
    generalError.value = ''
}

const searchTmdb = () => {
    loadingTmdb.value = true
    generalError.value = ''

    if (!contentTmdbId.value) {
        generalError.value = 'Content does not have a TMDB ID'
        loadingTmdb.value = false
        return
    }

    ajax.get(`/admin/contents/${props.content.id}/seasons-tmdb.json`)
        .then((response) => {
            tmdbResults.value = response.data?.data?.seasons || []
            loadingTmdb.value = false
        })
        .catch((error) => {
            generalError.value = error.response?.data?.error || 'Failed to fetch from TMDB'
            loadingTmdb.value = false
        })
}

const createSeasonFromData = (season) => {
    return ajax.post(`/admin/content-manager/${props.content.id}/seasons`, {
        season: {
            title: season.title,
            description: season.description || '',
            tmdb_id: season.tmdb_id,
        }
    })
}

const importSingle = (season) => {
    importingIds.value.push(season.tmdb_id)
    createSeasonFromData(season)
        .then(() => {
            tmdbResults.value = tmdbResults.value.filter(s => s.tmdb_id !== season.tmdb_id)
            emit('season-created')
        })
        .catch((error) => {
            generalError.value = error.response?.data?.errors?.[0] || 'Failed to create season'
        })
        .finally(() => {
            importingIds.value = importingIds.value.filter(id => id !== season.tmdb_id)
        })
}

const importAll = () => {
    loading.value = true
    generalError.value = ''

    const promises = tmdbResults.value.map(season => createSeasonFromData(season))

    Promise.all(promises)
        .then(() => {
            tmdbResults.value = []
            emit('season-created')
            setIsOpen(false)
        })
        .catch((error) => {
            generalError.value = 'Some seasons failed to import'
        })
        .finally(() => {
            loading.value = false
        })
}

const submitCreateSeason = () => {
    if (!canSubmit.value) return

    loading.value = true
    generalError.value = ''

    createSeasonFromData({
        title: seasonData.value.title,
        description: seasonData.value.description,
    })
        .then((response) => {
            emit('season-created', response)
            setIsOpen(false)
        })
        .catch((error) => {
            if (error.response?.data?.errors) {
                errors.value = error.response.data.errors
            } else {
                generalError.value = 'Failed to create season. Please try again.'
            }
        })
        .finally(() => {
            loading.value = false
        })
}
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
