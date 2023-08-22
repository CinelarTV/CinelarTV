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
                                        <c-input :modelValue="contentData.name" @update:modelValue="value => contentData.name = value"
                                            class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                                            placeholder="Avengers: Endgame" />
                                    </div>

                                    <label for="content_type" class="block text-sm font-medium mt-4">
                                        Type
                                    </label>
                                    <div class="mt-1">
                                        <c-select :options="contentTypes" 
                                            :modelValue="contentData.content_type" @update:modelValue="value => contentData.content_type = value"
                                            class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />
                                    </div>

                                    <label for="content_description" class="block text-sm font-medium mt-4">
                                        Description
                                    </label>
                                    <div class="mt-1">
                                        <c-textarea :modelValue="contentData.content_description" @update:modelValue="value => contentData.content_description = value"
                                            class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />

                                    </div>

                                    <label for="content_image" class="block text-sm font-medium mt-4">
                                        Image
                                    </label>
                                    <div class="mt-1">
                                        <c-input type="file" name="content_image" id="content_image"
                                            v-model="contentData.content_image"
                                            class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />

                                    </div>


                                </div>

                            </form>

                            <div class="flex mt-2 justify-center space-x-4">
                                <c-button v-if="contentData.name.length >= 3" @click="findRecommendedMetadata" :loading="loadingRecommendations">
                                    <SparklesIcon :size="18" class="icon" v-if="!loadingRecommendations" />
                                    Find recommended metadata
                                </c-button>
                            </div>

                            <RecommendedMetadataModal ref="metadataModal" :content="recommendedContent" @select-content="recommendedMetadataSelected" />


                        </DialogPanel>
                    </TransitionChild>
                </div>
            </div>
        </Dialog>
    </TransitionRoot>
</template>
  
<script setup>
import { onMounted, ref } from 'vue'
import { Dialog, DialogPanel, DialogTitle, TransitionChild, TransitionRoot } from '@headlessui/vue'
import axios from 'axios' // Import axios if not already imported
import { SparklesIcon } from 'lucide-vue-next';
import RecommendedMetadataModal from './recommended-metadata.modal.vue'

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
    content_image: ''
})
const recommendedContent = ref(null)
const metadataModal = ref()
const errors = ref()

const setIsOpen = (value) => {
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
    contentData.value.content_image = content.image;

    console.log(contentData.value)
}


const submitCreateContent = (e) => {
    e.preventDefault()
    loading.value = true
    errors.value = null

    // Modify data and endpoint based on your content creation requirements
    const data = {
        name: contentData.value.name,
        content_type: contentData.value.content_type,
        content_description: contentData.value.content_description,
        content_image: contentData.value.content_image

    }

    // Modify the API endpoint based on your requirements
    axios.post('/api/create-content', data)
        .then((response) => {
            loading.value = false
            setIsOpen(false)
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
    axios.get(`/admin/contents/recommended-metadata?title=${contentData.value.name}`)
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
  