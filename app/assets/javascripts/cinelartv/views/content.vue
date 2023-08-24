<template>
    <div class="mt-4 text-center" v-if="loading">
        <c-spinner />
    </div>
    <div v-else>
        <div class="content-overview" :data-content-id="$route.params.id">

        </div>
    </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const $route = useRoute()
const router = useRouter()

const loading = ref(true)
const contentData = ref(null)


const getContent = async () => {
    try {
        const { data } = await axios.get(`/contents/${$route.params.id}.json`)
        contentData.value = data
        loading.value = false
    } catch (error) {
        console.log(error)
        if(error.response.status === 404) {
            // Replace without changing path
            router.replace({
                name: 'application.not-found',
                replace: true
            }
            )
        }
    }

}

onMounted(() => {
    getContent()
})
</script>