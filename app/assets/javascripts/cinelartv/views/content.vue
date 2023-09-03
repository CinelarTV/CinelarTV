<template>
    <div class="mt-4 text-center" v-if="loading">
        <c-spinner />
    </div>
    <div v-else>
        <div class="content-overview" :data-content-id="$route.params.id">

            <h2 class="text-2xl font-bold mb-4">
                {{ contentData.content.title }}
            </h2>

        </div>
    </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useHead } from 'unhead'

const $route = useRoute()
const router = useRouter()

const loading = ref(true)
const contentData = ref({})


const getContent = async () => {
    try {
        const { data } = await axios.get(`/contents/${$route.params.id}.json`)
        contentData.value = data
        loading.value = false
    } catch (error) {
        console.log(error)
        if (error.response.status === 404) {
            // Replace without changing path
            router.replace({
                name: 'application.not-found',
                replace: true
            }
            )
        }
    }

}

onMounted(async () => {
    await getContent()
    useHead({
    title: contentData.value?.content?.title,
    meta: [
        {
            name: 'description',
            content: contentData.value?.content?.description
        }
    ]
})
})
</script>