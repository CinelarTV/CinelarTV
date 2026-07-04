<template>
    <TransitionRoot appear :show="isOpen" as="template">
        <Dialog as="div" class="relative z-50" @close="setIsOpen(false)">
            <!-- Backdrop -->
            <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0" enter-to="opacity-100"
                leave="duration-200 ease-in" leave-from="opacity-100" leave-to="opacity-0">
                <div class="fixed inset-0 bg-black/60 backdrop-blur-sm" />
            </TransitionChild>

            <!-- Modal container -->
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
                                Create New Episode
                            </DialogTitle>
                            <p class="mt-1 text-sm text-[var(--c-primary-100)]">
                                Fill in the details or import from TMDB
                            </p>
                        </div>

                        <!-- Form body -->
                        <div class="px-8 py-6 overflow-y-auto" style="max-height: calc(100vh - 220px);">
                            <form @submit="(e) => { e.preventDefault() }" novalidate>
                                <div class="space-y-4">
                                    <!-- TMDB Search -->
                                    <div v-if="SiteSettings.enable_metadata_recommendation" class="text-center">
                                        <button type="button" @click="searchTmdb"
                                            :disabled="loadingTmdb"
                                            class="inline-flex items-center gap-2 rounded-xl border border-[var(--c-primary-300)] bg-[var(--c-primary-200)] px-4 py-2.5 text-sm font-medium text-[var(--c-body-text-color)] transition-all hover:bg-[var(--c-primary-300)] disabled:cursor-not-allowed disabled:opacity-40">
                                            <Loader2 v-if="loadingTmdb" :size="15" class="animate-spin" />
                                            <SparklesIcon v-else :size="15" />
                                            {{ tmdbResults.length ? 'Refresh from TMDB' : 'Import from TMDB' }}
                                        </button>
                                        <p v-if="contentTmdbId" class="mt-1 text-[10px] text-[var(--c-primary-700)]">
                                            Using content TMDB ID: {{ contentTmdbId }}
                                        </p>
                                    </div>

                                    <!-- TMDB Results -->
                                    <div v-if="tmdbResults.length" class="space-y-2">
                                        <p class="text-xs font-medium text-[var(--c-primary-100)] uppercase tracking-wider">
                                            TMDB Episodes (select one)
                                        </p>
                                        <div class="max-h-48 overflow-y-auto space-y-1 custom-scrollbar">
                                            <button v-for="ep in tmdbResults" :key="ep.tmdb_id" type="button"
                                                @click="selectTmdbEpisode(ep)"
                                                :class="selectedTmdbId === ep.tmdb_id
                                                    ? 'ring-2 ring-[var(--c-tertiary-color)] bg-[var(--c-primary-300)]'
                                                    : 'hover:bg-[var(--c-primary-300)]'"
                                                class="w-full flex items-center gap-3 p-2 rounded-lg text-left transition-all">
                                                <img v-if="ep.thumbnail"
                                                    :src="`https://image.tmdb.org/t/p/w92${ep.thumbnail.replace('tmdb://', '/')}`"
                                                    class="w-12 h-8 object-cover rounded" />
                                                <div class="flex-1 min-w-0">
                                                    <p class="text-xs font-medium text-[var(--c-body-text-color)] truncate">
                                                        E{{ ep.episode_number }} - {{ ep.title }}
                                                    </p>
                                                    <p v-if="ep.air_date" class="text-[10px] text-[var(--c-primary-700)]">
                                                        {{ ep.air_date }}
                                                    </p>
                                                </div>
                                                <CheckIcon v-if="selectedTmdbId === ep.tmdb_id" :size="16"
                                                    class="text-[var(--c-tertiary-color)] shrink-0" />
                                            </button>
                                        </div>
                                    </div>

                                    <div class="relative flex items-center" v-if="SiteSettings.enable_metadata_recommendation">
                                        <div class="flex-grow border-t border-[var(--c-primary-200)]" />
                                        <span class="mx-3 text-xs text-[var(--c-primary-100)]">or fill manually</span>
                                        <div class="flex-grow border-t border-[var(--c-primary-200)]" />
                                    </div>

                                    <!-- Title -->
                                    <CFormRow label="Title" for="episode-title" :error="errors.title" required>
                                        <CInput v-model="episodeData.title" id="episode-title"
                                            placeholder="Episode Title" required />
                                    </CFormRow>

                                    <!-- Description -->
                                    <CFormRow label="Description" for="episode-description" :error="errors.description">
                                        <CTextarea v-model="episodeData.description" id="episode-description"
                                            placeholder="Enter episode description..." :rows="3" />
                                    </CFormRow>

                                    <!-- Thumbnail -->
                                    <CFormRow label="Thumbnail" for="episode-thumbnail" hint="Recommended: 16:9 ratio">
                                        <CImageUpload v-model="episodeData.thumbnail" aspect-ratio="16:9" />
                                    </CFormRow>

                                    <!-- Premium toggle -->
                                    <div
                                        class="flex items-center justify-between p-3 rounded-xl bg-yellow-500/10 border border-yellow-500/20">
                                        <div class="flex items-center gap-2">
                                            <SparklesIcon :size="16" class="text-yellow-500" />
                                            <div>
                                                <p
                                                    class="text-xs font-bold text-white uppercase tracking-wider">
                                                    Premium Episode</p>
                                                <p class="text-[10px] text-[var(--c-primary-100)]">Subscription
                                                    required</p>
                                            </div>
                                        </div>
                                        <button type="button"
                                            @click="episodeData.premium = !episodeData.premium"
                                            :class="episodeData.premium ? 'bg-yellow-500' : 'bg-white/10'"
                                            class="relative inline-flex h-5 w-9 items-center rounded-full transition-colors focus:outline-none">
                                            <span :class="episodeData.premium ? 'translate-x-5' : 'translate-x-1'"
                                                class="inline-block h-3 w-3 transform rounded-full bg-white transition-transform" />
                                        </button>
                                    </div>
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
                                    <button type="button" @click="submitCreateEpisode" :disabled="!canSubmit || loading"
                                        class="inline-flex items-center gap-2 rounded-xl bg-[var(--c-tertiary-color)] px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-all hover:bg-[var(--c-tertiary-100)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--c-tertiary-color)] disabled:cursor-not-allowed disabled:opacity-40">
                                        <Loader2 v-if="loading" :size="15" class="animate-spin" />
                                        <CheckIcon v-else :size="15" />
                                        Create Episode
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
} from 'lucide-vue-next'
import CInput from '../../../components/forms/c-input.vue'
import CTextarea from '../../../components/forms/c-textarea.vue'
import CImageUpload from '../../../components/forms/c-image-upload.vue'
import CFormRow from '../../../components/forms/CFormRow.tsx'
import { ajax } from '../../../lib/Ajax'

const SiteSettings = inject('SiteSettings')

const emit = defineEmits(['episode-created'])

const props = defineProps({
    contentId: String,
    seasonId: String,
    contentTmdbId: {
        type: [Number, String],
        default: null,
    },
    seasonNumber: {
        type: [Number, String],
        default: null,
    },
})

const isOpen = ref(false)
const loading = ref(false)
const loadingTmdb = ref(false)
const generalError = ref('')
const errors = ref({})
const tmdbResults = ref([])
const selectedTmdbId = ref(null)

const episodeData = ref({
    title: '',
    description: '',
    thumbnail: '',
    premium: false,
})

const canSubmit = computed(() => {
    return episodeData.value.title.trim().length >= 1 && !loading.value
})

const setIsOpen = (value) => {
    clearData()
    isOpen.value = value
}

defineExpose({
    setIsOpen,
})

const clearData = () => {
    episodeData.value = {
        title: '',
        description: '',
        thumbnail: '',
        premium: false,
    }
    tmdbResults.value = []
    selectedTmdbId.value = null
    errors.value = {}
    generalError.value = ''
}

const searchTmdb = () => {
    loadingTmdb.value = true
    generalError.value = ''

    const tmdbId = props.contentTmdbId

    if (!tmdbId) {
        generalError.value = 'Content does not have a TMDB ID'
        loadingTmdb.value = false
        return
    }

    const params = { tmdb_id: tmdbId }
    if (props.seasonNumber) {
        params.season_number = props.seasonNumber
    }

    ajax.get(`/admin/content-manager/${props.contentId}/seasons/${props.seasonId}/episodes-tmdb.json`, {
        params,
    })
        .then((response) => {
            tmdbResults.value = response.data?.data?.episodes || []
            loadingTmdb.value = false
        })
        .catch((error) => {
            generalError.value = error.response?.data?.error || 'Failed to fetch from TMDB'
            loadingTmdb.value = false
        })
}

const selectTmdbEpisode = (ep) => {
    selectedTmdbId.value = ep.tmdb_id
    episodeData.value.title = ep.title || ''
    episodeData.value.description = ep.description || ''
    episodeData.value.thumbnail = ep.thumbnail || ''
}

const submitCreateEpisode = () => {
    if (!canSubmit.value) return

    loading.value = true
    generalError.value = ''

    const formData = new FormData()

    const data = {
        title: episodeData.value.title,
        description: episodeData.value.description,
        thumbnail: episodeData.value.thumbnail,
        premium: episodeData.value.premium,
        season_id: props.seasonId,
        tmdb_id: selectedTmdbId.value,
    }

    for (const key in data) {
        if (data[key] !== null && data[key] !== undefined && data[key] !== '') {
            formData.append(`episode[${key}]`, data[key])
        }
    }

    ajax.post(`/admin/content-manager/${props.contentId}/seasons/${props.seasonId}/episodes.json`, formData)
        .then((response) => {
            loading.value = false
            setIsOpen(false)
            emit('episode-created', true)
        })
        .catch((error) => {
            loading.value = false
            if (error.response?.data?.errors) {
                errors.value = error.response.data.errors
            } else {
                generalError.value = 'Failed to create episode. Please try again.'
            }
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
