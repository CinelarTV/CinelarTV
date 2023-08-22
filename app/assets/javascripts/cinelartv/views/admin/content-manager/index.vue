<template>
    <div class="mx-auto">
        <c-spinner v-if="loading" />
        <template v-else>
            <div class="py-8" v-if="content.length === 0">
                <div class="flex flex-col items-center justify-center">
                    <div class="text-2xl font-bold text-gray-500">
                        {{ $t("js.admin.content_manager.no_content") }}
                    </div>
                    <div class="text-gray-500">
                        {{ $t("js.admin.content_manager.no_content_description") }}
                    </div>
                    <div class="mt-4">
                        <c-button @click="createContent" class="bg-blue-500 hover:bg-blue-600">
                            {{ $t("js.admin.content_manager.create_content") }}
                        </c-button>
                    </div>
                </div>
            </div>
        </template>
        <CreateContentModal ref="createContentModal" />
    </div>
</template>

<script setup>
import { ref, getCurrentInstance, onMounted } from 'vue'
import { SiteSettings } from '../../../pre-initializers/essentials-preload'
import { currentUser } from '../../../pre-initializers/essentials-preload'
import CreateContentModal from '../../../components/modals/create-content.modal.vue';

const { $t } = getCurrentInstance().appContext.config.globalProperties

const loading = ref(true)
const content = ref([])
const createContentModal = ref(null)
const createContent = () => {
    createContentModal.value.setIsOpen(true)
}


const fetchContent = () => {
    loading.value = true
    axios.get('/admin/content-manager/all.json').then((response) => {
        loading.value = false
        content.value = response.data.data
    }).catch((error) => {
        console.log(error);
    });
}

onMounted(() => {
    fetchContent()
})

</script>
