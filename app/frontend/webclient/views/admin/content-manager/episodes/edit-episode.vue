<template>
    <div class="mt-4" v-if="loading">
        <div class="flex justify-center">
            <c-spinner />
        </div>

    </div>
    <div class="flex flex-col mt-4" v-else>
        <div class="flex flex-row justify-between items-center">
            <div class="flex">
                <c-button @click="backToEditor" icon="chevron-left">
                    Regresar
                </c-button>
            </div>
            <div class="flex">
                <c-button @click="saveEpisode" icon="check" :loading="saving">
                    Guardar
                </c-button>
            </div>
        </div>
        <div class="flex flex-col mt-4">
            <div class="flex flex-col">
                <c-input v-model="episodeData.title" placeholder="Título" />
            </div>
            <div class="flex flex-col mt-4">
                <c-textarea v-model="episodeData.description" placeholder="Descripción" />
            </div>
            <div class="flex flex-col mt-4">
                <c-input v-model="episodeData.url" placeholder="URL" />
            </div>
            <div class="flex flex-col mt-4">
                <CImageUpload v-model="episodeData.thumbnail" placeholder="Thumbnail" :accept="'image/*'" />
            </div>

        </div>
    </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue';
import { ajax } from '../../../../lib/Ajax';
import { CheckIcon } from 'lucide-vue-next';
import { ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { toast } from 'vue3-toastify';
import CImageUpload from "@/components/forms/CImageUpload";

const router = useRouter();
const route = useRoute();

const episodeData = ref({
    title: '',
    description: '',
    url: '',
    thumbnail: null as File | null,
});

const backToEditor = () => {
    router.push({
        name: 'admin.content.manager.manage-episodes',
        params: {
            contentId: route.params.contentId.toString(),
            seasonId: route.params.seasonId.toString(),
        },
    });
}

const loading = ref(false);
const saving = ref(false);

const fetchEpisodeData = async () => {
    loading.value = true;
    const response = await ajax.get(`/admin/content-manager/${route.params.contentId}/seasons/${route.params.seasonId}/episodes/${route.params.episodeId}/edit.json`);
    episodeData.value = response.data.data.episode
    loading.value = false;
}

const saveEpisode = async () => {
    saving.value = true;
    try {
        const formData = new FormData();
        formData.append('title', episodeData.value.title);
        formData.append('description', episodeData.value.description);
        formData.append('url', episodeData.value.url);
        if (episodeData.value.thumbnail) {
            formData.append('thumbnail', episodeData.value.thumbnail);
        }

        const response = await ajax.put(`/admin/content-manager/${route.params.contentId}/seasons/${route.params.seasonId}/episodes/${route.params.episodeId}/edit.json`, formData, {
            headers: { 'Content-Type': 'multipart/form-data' },
        });

        toast.success('Episodio guardado correctamente');
        fetchEpisodeData();
    } catch (error) {
        toast.error('Hubo un error al guardar el episodio');
    } finally {
        saving.value = false;
    }
}

onMounted(() => {
    fetchEpisodeData();
})
</script>