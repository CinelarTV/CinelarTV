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
                        <c-button @click="createContent" class="bg-blue-500 hover:bg-blue-600 text-white">
                            {{ $t("js.admin.content_manager.create_content") }}
                        </c-button>
                    </div>
                </div>
            </div>
            <div v-else>
                <div class="flex justify-between items-center mb-4">
                    <div class="mt-4 ml-auto">
                        <c-button @click="createContent" class="bg-blue-500 hover:bg-blue-600 text-white">
                            <PlusIcon class="icon" :size="18" />
                            {{ $t("js.admin.content_manager.create_content") }}
                        </c-button>
                    </div>
                </div>
                <div class="overflow-x-auto">
                    <table class="w-full table-auto border border-[var(--c-primary-color)]">
                        <thead>
                            <tr class="bg-[var(--c-primary-50)]">
                                <th class="px-4 py-2">{{ $t("js.admin.content_manager.id") }}</th>
                                <th class="px-4 py-2">{{ $t("js.admin.content_manager.content_title") }}</th>
                                <th class="px-4 py-2">{{ $t("js.admin.content_manager.content_type") }}</th>
                                <th class="px-4 py-2">{{ $t("js.admin.content_manager.content_cover") }}</th>
                                <th class="px-4 py-2">{{ $t("js.admin.content_manager.actions") }}</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr v-for="item in content" :key="item.id" class="border-t border-[var(--c-primary-color)]">
                                <td class="px-4 py-2" :title="item.id">
                                    {{ item.id.slice(0, 8) }}...
                                </td>
                                <td class="px-4 py-2">{{ item.title }}</td>
                                <td class="px-4 py-2">{{ $t(`js.admin.content_manager.content_types.${item.content_type}`)
                                }}</td>
                                <td class="px-4 py-2">
                                    <img :src="item.cover" class="w-24 rounded-lg" />
                                </td>
                                <td class="px-4 py-2">
                                    <c-button @click="editContent(item)" class="bg-blue-500 hover:bg-blue-600 text-white">
                                        {{ $t("js.admin.actions.edit") }}
                                    </c-button>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </template>
        <CreateContentModal ref="createContentModal" @content-created="fetchContent" />
    </div>
</template>
  
<script setup>
import { ref, getCurrentInstance, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import CreateContentModal from '../../../components/modals/create-content.modal.vue';
import { PlusIcon } from 'lucide-vue-next';
import { ajax } from '../../../lib/Ajax';
const { $t } = getCurrentInstance().appContext.config.globalProperties
const router = useRouter()

const loading = ref(true)
const content = ref([])
const createContentModal = ref(null)

const editContent = (item) => {
    router.push({
        name: 'admin.content.manager.edit',
        params: {
            id: item.id
        }
    })
}

const createContent = () => {
    createContentModal.value.setIsOpen(true)
}

const fetchContent = async () => {
    loading.value = true
    try {
        const response = await ajax.get('/admin/content-manager/all.json')
        content.value = response.data.data
    } catch (error) {
        console.log(error)
    }
    loading.value = false
}

onMounted(() => {
    fetchContent()
})

</script>
  ../../../lib/ajax