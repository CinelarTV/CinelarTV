<template>
    <div v-if="loading">
        <c-spinner />
    </div>
    <div v-else>
        <div class="panel">
            <div class="panel-header">
                <div class="panel-title">
                    {{ $t('js.admin.content_manager.edit') }}
                </div>
            </div>
            <div class="panel-body">
                <div class="edit-content" :data-content-id="$route.params.id">
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
    import { onMounted, ref } from 'vue';
import { useRoute } from 'vue-router'
    const route = useRoute()

    const contentId = route.params.id
    const loading = ref(true)
    const content = ref()

    const fetchContent = async () => {
        try {
            const response = await axios.get(`/admin/content-manager/${contentId}.json`)
            content.value = response.data.data
        } catch (error) {
            console.log(error)
        } finally {
            loading.value = false
        }
    }

    onMounted(() => {
        fetchContent()
    })

</script>