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
                            class="dialog create-content w-full max-w-md transform overflow-hidden rounded-2xl p-6 text-left align-middle shadow-xl transition-all">
                            <!-- Your content creation form here -->
                            <DialogTitle as="h3" class="text-lg font-medium leading-6 text-[var(--primary-600)]" v-emoji>
                                ¡Let's create some content! ✅
                            </DialogTitle>


                            <form @submit="submitCreateContent">
                                <div class="mt-4">
                                    <label for="name" class="block text-sm font-medium">
                                        Name
                                    </label>
                                    <div class="mt-1">
                                        <c-input :modelValue="contentData.name"
                                            @update:modelValue="value => contentData.name = value"
                                            class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                                            placeholder="Avengers: Endgame" />
                                    </div>

                                    <label for="content_type" class="block text-sm font-medium mt-4">
                                        Type
                                    </label>
                                    <div class="mt-1">
                                        <c-select :options="contentTypes" :modelValue="contentData.content_type"
                                            @update:modelValue="value => contentData.content_type = value"
                                            class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />
                                    </div>

                                    <label for="content_description" class="block text-sm font-medium mt-4">
                                        Description
                                    </label>
                                    <div class="mt-1">
                                        <c-textarea :modelValue="contentData.content_description"
                                            @update:modelValue="value => contentData.content_description = value"
                                            class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />

                                    </div>

                                    <label for="content_image" class="block text-sm font-medium mt-4">
                                        Image
                                    </label>
                                    <div class="mt-1">
                                        <c-image-upload v-model="contentData.content_cover"
                                            @update:model-value="value => contentData.content_cover = value"
                                            class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />


                                    </div>

                                    <label for="content_banner" class="block text-sm font-medium mt-4">
                                        Banner
                                    </label>
                                    <div class="mt-1">
                                        <c-image-upload v-model="contentData.content_banner"
                                            @update:model-value="value => contentData.content_banner = value"
                                            class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />




                                    </div>


                                </div>

                            </form>

                            <div class="flex mt-2 justify-center space-x-4">
                                <c-button v-if="contentData.name.length >= 3 && SiteSettings.enable_metadata_recommendation"
                                    @click="findRecommendedMetadata" :loading="loadingRecommendations">
                                    <SparklesIcon :size="18" class="icon" v-if="!loadingRecommendations" />
                                    Find recommended metadata
                                </c-button>
                                <c-button @click="submitCreateContent" :loading="loading">
                                    <CheckIcon :size="18" class="icon" v-if="!loading" />
                                    Create content
                                </c-button>
                            </div>

                            <RecommendedMetadataModal ref="metadataModal" :content="recommendedContent"
                                @select-content="recommendedMetadataSelected" />


                        </DialogPanel>
                    </TransitionChild>
                </div>
            </div>
        </Dialog>
    </TransitionRoot>
</template>
  
<script setup>
import { getCurrentInstance, onMounted, ref, inject } from 'vue'
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'
import { CheckIcon, SparklesIcon } from 'lucide-vue-next';
import RecommendedMetadataModal from './recommended-metadata.modal.vue'
import cImageUpload from '../forms/c-image-upload.vue';
import { ajax } from '../../lib/Ajax';

const SiteSettings = inject('SiteSettings');

const emit = defineEmits(['content-created'])

const props = defineProps({
    // Define your props here
})

const contentTypes = ref([
    { value: 'MOVIE', label: 'Movie' },
    { value: 'TVSHOW', label: 'Serie' }
])

const isOpen = ref(false)
const loading = ref(false)
const loadingRecommendations = ref(false)
const contentData = ref({
    name: '',
    content_type: '',
    content_description: '',
    content_cover: '',
    content_banner: '',
})
const recommendedContent = ref(null)
const metadataModal = ref()
const errors = ref()

const setIsOpen = (value) => {
    clearData()
    isOpen.value = value
}

defineExpose({
    setIsOpen
})

const recommendedMetadataSelected = (content) => {
    console.log(content)
    // Actualiza las propiedades individuales en lugar de asignar un nuevo objeto
    contentData.value.name = content.title || content.name || content.original_name;
    contentData.value.content_type = content.media_type === 'movie' ? 'MOVIE' : 'TVSHOW';
    contentData.value.content_description = content.overview;
    contentData.value.content_cover = 'tmdb://' + content.poster_path.replace('/', '');
    contentData.value.content_banner = 'tmdb://' + content.backdrop_path.replace('/', '');

    console.log(contentData.value)
}

const clearData = () => {
    contentData.value.name = ''
    contentData.value.content_type = ''
    contentData.value.content_description = ''
    contentData.value.content_cover = ''
    contentData.value.content_banner = ''
}


const submitCreateContent = (e) => {
    e.preventDefault()
    loading.value = true
    errors.value = null

    const formData = new FormData()

    // Modify data and endpoint based on your content creation requirements
    const data = {
        title: contentData.value.name,
        content_type: contentData.value.content_type,
        description: contentData.value.content_description,
        cover: contentData.value.content_cover,
        banner: contentData.value.content_banner
    }

    for (e in data) {
        formData.append(`content[${e}]`, data[e])
    }

    ajax.post('/admin/contents.json', formData)
        .then((response) => {
            loading.value = false
            setIsOpen(false)
            emit('content-created', response.data)
            // Handle successful response
        })
        .catch((error) => {
            loading.value = false
            errors.value = error.response.data.errors
        })
}

const findRecommendedMetadata = () => {
    loadingRecommendations.value = true
    // Modify the API endpoint based on your requirements
    ajax.get(`/admin/contents/recommended-metadata.json?title=${contentData.value.name}`)
        .then((response) => {
            console.log(response.data)
            recommendedContent.value = response.data
            metadataModal.value.open()
            loadingRecommendations.value = false
        })
        .catch((error) => {
            console.error(error)
            errors.value = error.response
            loadingRecommendations.value = false
        })
}
</script>
  ../../lib/ajax