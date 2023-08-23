<template>
    <div v-if="loading">
        <c-spinner />
    </div>
    <div v-else>
        <div class="panel">
            <div class="panel-header">
                <div class="panel-title">
                    {{ content.title }}
                </div>
            </div>
            <div class="panel-body">
                <div class="edit-content" :data-content-id="$route.params.id">

                    <form @submit="saveContent">
                        <c-input v-model="content.title" label="Title" @update:modelValue="content.title = $event" />


                        <c-select v-model="content.content_type" label="Type" :options="contentTypes" @update:modelValue="content.content_type = $event" />

                        <c-textarea v-model="content.description" label="Description" @update:modelValue="content.description = $event" />

                        <c-image-upload v-model="content.cover" label="Cover" @update:modelValue="content.cover = $event" />

                        <c-image-upload v-model="content.banner" label="Banner" @update:modelValue="content.banner = $event" />

                        <c-input type="number" v-model="content.year" label="Year" @update:modelValue="content.year = $event" />

                        <c-button type="submit" :loading="loadingButton">
                            Save
                        </c-button>
                    </form>

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

    const loadingButton = ref(false)

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

    const saveContent = async (e) => {
        e.preventDefault()
        loadingButton.value = true
        try {
            const formData = new FormData()
            Object.entries(content.value).forEach(([key, value]) => {
                if (['id', 'created_at', 'updated_at'].includes(key)) {
                    return
                }
                formData.append(`content[${key}]`, value)
            })

            const response = await axios.put(`/admin/content-manager/${contentId}.json`, formData)

            await fetchContent()
        } catch (error) {
            console.log(error)

        } finally {
            loadingButton.value = false
        }
    }



    onMounted(() => {
        fetchContent()
    })

</script>