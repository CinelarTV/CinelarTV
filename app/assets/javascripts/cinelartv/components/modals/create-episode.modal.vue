<template>
    <TransitionRoot appear :show="isOpen" as="template">
        <Dialog as="div" @close="setIsOpen(false)" class="modal">
            <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0" enter-to="opacity-100"
                leave="duration-200 ease-in" leave-from="opacity-100" leave-to="opacity-0">
                <div class="fixed inset-0 bg-black bg-opacity-95 z-[102]" />
            </TransitionChild>

            <div class="fixed inset-0 overflow-y-auto z-[102]">
                <div class="flex min-h-full items-center justify-center p-4 text-center">
                    <TransitionChild as="template" enter="duration-300 ease-out" enter-from="opacity-0 scale-95"
                        enter-to="opacity-100 scale-100" leave="duration-200 ease-in" leave-from="opacity-100 scale-100"
                        leave-to="opacity-0 scale-95">
                        <DialogPanel
                            class="dialog create-episode w-full max-w-md transform overflow-hidden rounded-2xl p-6 text-left align-middle shadow-xl transition-all">
                            <DialogTitle as="h3" class="text-lg font-medium leading-6 text-[var(--primary-600)]" v-emoji>
                                ¡Let's create an episode! ✅
                            </DialogTitle>

                            <form @submit="submitCreateEpisode">
                                <div class="mt-4">
                                    <label for="title" class="block text-sm font-medium">
                                        Title
                                    </label>
                                    <div class="mt-1">
                                        <c-input :modelValue="episodeData.title"
                                            @update:modelValue="value => episodeData.title = value"
                                            class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md"
                                            placeholder="Episode Title" />
                                    </div>

                                    <label for="description" class="block text-sm font-medium mt-4">
                                        Description
                                    </label>
                                    <div class="mt-1">
                                        <c-textarea :modelValue="episodeData.description"
                                            @update:modelValue="value => episodeData.description = value"
                                            class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />
                                    </div>

                                   
                                    <label for="thumbnail" class="block text-sm font-medium mt-4">
                                        Thumbnail
                                    </label>
                                    <div class="mt-1">
                                        <c-image-upload v-model="episodeData.thumbnail"
                                            @update:model-value="value => episodeData.thumbnail = value"
                                            class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md" />
                                    </div>

                                    <input type="hidden" :value="seasonId" name="season_id" />

                                </div>
                            </form>

                            <div class="flex mt-2 justify-center space-x-4">
                                <c-button @click="submitCreateEpisode" :loading="loading">
                                    <CheckIcon :size="18" class="icon" v-if="!loading" />
                                    Create episode
                                </c-button>
                            </div>

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
import { CheckIcon } from 'lucide-vue-next';
import cImageUpload from '../forms/c-image-upload.vue';
import { ajax } from '../../lib/axios-setup';

const SiteSettings = inject('SiteSettings');

const emit = defineEmits(['episode-created'])

const props = defineProps({
    contentId: String, // Pass the content ID as a prop
    seasonId: String, // Pass the season ID as a prop
})

const isOpen = ref(false)
const loading = ref(false)
const episodeData = ref({
    title: '',
    description: '',
    url: '',
    thumbnail: '',
})

const setIsOpen = (value) => {
    clearData()
    isOpen.value = value
}

defineExpose({
    setIsOpen
})

const clearData = () => {
    episodeData.value.title = ''
    episodeData.value.description = ''
    episodeData.value.url = ''
    episodeData.value.thumbnail = ''
}

const submitCreateEpisode = (e) => {
    e.preventDefault()
    loading.value = true

    const formData = new FormData()

    // Modify data and endpoint based on your episode creation requirements
    const data = {
        title: episodeData.value.title,
        description: episodeData.value.description,
        url: episodeData.value.url,
        thumbnail: episodeData.value.thumbnail,
        season_id: props.seasonId, // Use the provided seasonId prop
    }

    for (e in data) {
        formData.append(`episode[${e}]`, data[e])
    }

    ajax.post(`/admin/content-manager/${props.contentId}/seasons/${props.seasonId}/episodes.json`, formData)
        .then((response) => {
            loading.value = false
            setIsOpen(false)
            emit('episode-created', true)
            // Handle successful response
        })
        .catch((error) => {
            loading.value = false
            // Handle error response
        })
}
</script>
