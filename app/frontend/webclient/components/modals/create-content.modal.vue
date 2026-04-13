<template>
    <TransitionRoot appear :show="isOpen" as="template">
        <Dialog as="div" class="relative z-50" @close="handleDialogClose">
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
                        class="w-full max-w-lg rounded-2xl overflow-hidden shadow-2xl ring-1 ring-[var(--c-primary-200)] bg-[var(--c-primary-100)]"
                        @click.stop>

                        <!-- Header with progress -->
                        <div
                            class="bg-[var(--c-primary-color)] px-8 pt-8 pb-6 text-center border-b border-[var(--c-primary-200)]">
                            <DialogTitle as="h2"
                                class="text-xl font-semibold tracking-tight text-[var(--c-body-text-color)]">
                                Create New Content
                            </DialogTitle>
                            <p class="mt-1 text-sm text-[var(--c-primary-900)]">
                                Step {{ currentStep }} of {{ totalSteps }}
                            </p>

                            <!-- Progress bar -->
                            <div class="mt-4 flex gap-2 justify-center">
                                <div v-for="step in totalSteps" :key="step"
                                    class="h-1 rounded-full transition-all duration-300" :class="[
                                        step <= currentStep
                                            ? 'w-8 bg-[var(--c-tertiary-color)]'
                                            : 'w-4 bg-[var(--c-primary-300)]'
                                    ]" />
                            </div>
                        </div>

                        <!-- Form body -->
                        <div class="px-8 py-6">
                            <form @submit="(e) => { e.preventDefault() }" novalidate>

                                <!-- Step 1: Basic Info -->
                                <Transition enter-active-class="transition-all duration-300 ease-out"
                                    enter-from-class="opacity-0 translate-x-4"
                                    enter-to-class="opacity-100 translate-x-0"
                                    leave-active-class="transition-all duration-200 ease-in"
                                    leave-from-class="opacity-100 translate-x-0"
                                    leave-to-class="opacity-0 -translate-x-4">
                                    <div v-if="currentStep === 1" key="step1">
                                        <div class="space-y-4">
                                            <div>
                                                <label for="content-name"
                                                    class="block text-xs font-medium uppercase tracking-widest text-[var(--c-primary-900)] mb-1.5">
                                                    Content Name
                                                </label>
                                                <CInput v-model="contentData.name" id="content-name"
                                                    placeholder="Avengers: Endgame" required />
                                                <p v-if="errors.name" class="mt-1 text-xs text-rose-400">
                                                    {{ errors.name }}
                                                </p>
                                            </div>

                                            <div>
                                                <label for="content-type"
                                                    class="block text-xs font-medium uppercase tracking-widest text-[var(--c-primary-900)] mb-1.5">
                                                    Content Type
                                                </label>
                                                <CSelect :options="contentTypes" :modelValue="contentData.content_type"
                                                    @update:modelValue="value => contentData.content_type = value"
                                                    id="content-type" placeholder="Select type..." />
                                                <p v-if="errors.content_type" class="mt-1 text-xs text-rose-400">
                                                    {{ errors.content_type }}
                                                </p>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- Step 2: Description -->
                                    <div v-else-if="currentStep === 2" key="step2">
                                        <div class="space-y-4">
                                            <div>
                                                <label for="content-description"
                                                    class="block text-xs font-medium uppercase tracking-widest text-[var(--c-primary-900)] mb-1.5">
                                                    Description
                                                </label>
                                                <CTextarea v-model="contentData.content_description"
                                                    id="content-description"
                                                    placeholder="Enter a compelling description..." :rows="4" />
                                                <p v-if="errors.description" class="mt-1 text-xs text-rose-400">
                                                    {{ errors.description }}
                                                </p>
                                            </div>

                                            <!-- Metadata recommendation -->
                                            <div v-if="SiteSettings.enable_metadata_recommendation" class="pt-2">
                                                <div class="relative flex items-center">
                                                    <div class="flex-grow border-t border-[var(--c-primary-200)]" />
                                                    <span
                                                        class="mx-3 text-xs text-[var(--c-primary-900)]">optional</span>
                                                    <div class="flex-grow border-t border-[var(--c-primary-200)]" />
                                                </div>

                                                <div class="mt-4 text-center">
                                                    <p class="text-sm text-[var(--c-primary-900)] mb-3">
                                                        Want to auto-fill metadata?
                                                    </p>
                                                    <button type="button" @click="findRecommendedMetadata"
                                                        :disabled="loadingRecommendations"
                                                        class="inline-flex items-center gap-2 rounded-xl border border-[var(--c-primary-300)] bg-[var(--c-primary-200)] px-4 py-2.5 text-sm font-medium text-[var(--c-body-text-color)] transition-all hover:bg-[var(--c-primary-300)] disabled:cursor-not-allowed disabled:opacity-40">
                                                        <Loader2 v-if="loadingRecommendations" :size="15"
                                                            class="animate-spin" />
                                                        <SparklesIcon v-else :size="15" />
                                                        Find recommended metadata
                                                    </button>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    <!-- Step 3: Images -->
                                    <div v-else-if="currentStep === 3" key="step3">
                                        <div class="space-y-4">
                                            <div>
                                                <label
                                                    class="block text-xs font-medium uppercase tracking-widest text-[var(--c-primary-900)] mb-1">
                                                    Cover Image
                                                </label>
                                                <CImageUpload v-model="contentData.content_cover" aspect-ratio="2:3"
                                                    hint="Recommended: 2:3 ratio (portrait)" />
                                                <p v-if="errors.cover" class="mt-1 text-xs text-rose-400">
                                                    {{ errors.cover }}
                                                </p>
                                            </div>

                                            <div>
                                                <label
                                                    class="block text-xs font-medium uppercase tracking-widest text-[var(--c-primary-900)] mb-1">
                                                    Banner Image
                                                </label>
                                                <CImageUpload v-model="contentData.content_banner" aspect-ratio="16:9"
                                                    hint="Recommended: 16:9 ratio (landscape)" />
                                                <p v-if="errors.banner" class="mt-1 text-xs text-rose-400">
                                                    {{ errors.banner }}
                                                </p>
                                            </div>
                                        </div>
                                    </div>
                                </Transition>

                                <!-- Navigation buttons -->
                                <div class="mt-6 flex items-center justify-between gap-3">
                                    <!-- Previous button -->
                                    <button v-if="currentStep > 1" type="button" @click="previousStep"
                                        class="inline-flex items-center gap-2 rounded-xl border border-[var(--c-primary-300)] bg-[var(--c-primary-200)] px-4 py-2.5 text-sm font-medium text-[var(--c-body-text-color)] transition-all hover:bg-[var(--c-primary-300)]">
                                        <ArrowLeftIcon :size="15" />
                                        Previous
                                    </button>

                                    <div class="ml-auto flex gap-3">
                                        <!-- Next button -->
                                        <button v-if="currentStep < totalSteps" type="button" @click="nextStep"
                                            :disabled="!canProceed"
                                            class="inline-flex items-center gap-2 rounded-xl bg-[var(--c-tertiary-color)] px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-all hover:bg-[var(--c-tertiary-100)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--c-tertiary-color)] disabled:cursor-not-allowed disabled:opacity-40">
                                            Next
                                            <ArrowRightIcon :size="15" />
                                        </button>

                                        <!-- Create button -->
                                        <button v-else type="button" @click="submitCreateContent" :disabled="!canSubmit"
                                            class="inline-flex items-center gap-2 rounded-xl bg-[var(--c-tertiary-color)] px-5 py-2.5 text-sm font-semibold text-white shadow-sm transition-all hover:bg-[var(--c-tertiary-100)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--c-tertiary-color)] disabled:cursor-not-allowed disabled:opacity-40">
                                            <Loader2 v-if="loading" :size="15" class="animate-spin" />
                                            <CheckIcon v-else :size="15" />
                                            Create Content
                                        </button>
                                    </div>
                                </div>

                                <!-- General error message -->
                                <p v-if="generalError" class="mt-4 text-xs font-medium text-center text-rose-400">
                                    {{ generalError }}
                                </p>

                            </form>
                        </div>

                    </DialogPanel>
                </TransitionChild>
            </div>
        </Dialog>
    </TransitionRoot>

    <!-- Metadata recommendation modal -->
    <RecommendedMetadataModal ref="metadataModal" :content="recommendedContent"
        @select-content="recommendedMetadataSelected" @close="onMetadataModalClose" />
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
    ArrowLeftIcon,
    ArrowRightIcon,
    Loader2,
} from 'lucide-vue-next'
import CInput from '../forms/c-input.vue'
import CSelect from '../forms/c-select.vue'
import CTextarea from '../forms/c-textarea.vue'
import CImageUpload from '../forms/c-image-upload.vue'
import RecommendedMetadataModal from './recommended-metadata.modal.vue'
import { ajax } from '../../lib/Ajax'

const SiteSettings = inject('SiteSettings')

const emit = defineEmits(['content-created'])

const props = defineProps({})

const contentTypes = ref([
    { value: 'MOVIE', label: 'Movie' },
    { value: 'TVSHOW', label: 'TV Series' }
])

const isOpen = ref(false)
const currentStep = ref(1)
const totalSteps = 3
const loading = ref(false)
const loadingRecommendations = ref(false)
const generalError = ref('')
const errors = ref({})
const isMetadataModalOpen = ref(false)
const contentData = ref({
    name: '',
    content_type: '',
    content_description: '',
    content_cover: '',
    content_banner: '',
})
const recommendedContent = ref(null)
const metadataModal = ref()

// Computed
const canProceed = computed(() => {
    if (currentStep.value === 1) {
        return contentData.value.name.length >= 3 && contentData.value.content_type
    }
    return true
})

const canSubmit = computed(() => {
    return canProceed.value && !loading.value
})

// Methods
const handleDialogClose = () => {
    // Don't close parent if child metadata modal is open
    if (isMetadataModalOpen.value) {
        return
    }
    setIsOpen(false)
}

const setIsOpen = (value) => {
    clearData()
    currentStep.value = 1
    isOpen.value = value
}

const nextStep = () => {
    if (canProceed.value && currentStep.value < totalSteps) {
        currentStep.value++
        errors.value = {}
        generalError.value = ''
    }
}

const previousStep = () => {
    if (currentStep.value > 1) {
        currentStep.value--
        errors.value = {}
        generalError.value = ''
    }
}

const clearData = () => {
    contentData.value = {
        name: '',
        content_type: '',
        content_description: '',
        content_cover: '',
        content_banner: '',
    }
    errors.value = {}
    generalError.value = ''
    currentStep.value = 1
}

const recommendedMetadataSelected = (content) => {
    contentData.value.name = content.title || content.name || content.original_name
    contentData.value.content_type = content.media_type === 'movie' ? 'MOVIE' : 'TVSHOW'
    contentData.value.content_description = content.overview
    contentData.value.content_cover = 'tmdb://' + content.poster_path.replace('/', '')
    contentData.value.content_banner = 'tmdb://' + content.backdrop_path.replace('/', '')
}

const submitCreateContent = async () => {
    if (!canSubmit.value) return

    loading.value = true
    errors.value = {}
    generalError.value = ''

    const formData = new FormData()
    const data = {
        title: contentData.value.name,
        content_type: contentData.value.content_type,
        description: contentData.value.content_description,
        cover: contentData.value.content_cover,
        banner: contentData.value.content_banner,
    }

    for (const key in data) {
        if (data[key]) {
            formData.append(`content[${key}]`, data[key])
        }
    }

    try {
        const response = await ajax.post('/admin/contents.json', formData)
        loading.value = false
        setIsOpen(false)
        emit('content-created', response.data)
    } catch (error) {
        loading.value = false
        if (error.response?.data?.errors) {
            errors.value = error.response.data.errors
        } else {
            generalError.value = 'Failed to create content. Please try again.'
        }
    }
}

const findRecommendedMetadata = () => {
    loadingRecommendations.value = true
    ajax.get(`/admin/contents/recommended-metadata.json?title=${contentData.value.name}`)
        .then((response) => {
            recommendedContent.value = response.data
            isMetadataModalOpen.value = true
            metadataModal.value?.open()
            loadingRecommendations.value = false
        })
        .catch((error) => {
            console.error(error)
            loadingRecommendations.value = false
        })
}

const onMetadataModalClose = (selected) => {
    isMetadataModalOpen.value = false
    // If no selection was made, that's fine - user can try again
}

defineExpose({
    setIsOpen
})
</script>