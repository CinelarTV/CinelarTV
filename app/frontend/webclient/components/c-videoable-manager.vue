<template>
    <div class="videoable-manager">
        <div v-if="videoSources.length === 0" class="video-sources-empty">
            <c-icon icon="frown" size="48" />
            <p>
                Parece que no hay fuentes de video para este contenido.
            </p>
        </div>

        <div class="videoable-create" v-if="creatingVideoSource">
    <h3 class="videoable-create-title">Agregar fuente de video</h3>
    <label>Origen del video:</label>
    <div>
        <input type="radio" id="fileSource" v-model="newVideoSource.source" value="file" />
        <label for="fileSource">Archivo</label>
        <input type="radio" id="urlSource" v-model="newVideoSource.source" value="url" />
        <label for="urlSource">URL</label>
    </div>
    <!-- Aquí puedes mostrar un drag and drop para subir el archivo si newVideoSource.source es 'file' -->
    <!-- O mostrar un input para ingresar la URL si newVideoSource.source es 'url' -->
</div>


        <footer class="video-sources-footer">
            <c-button @click="addVideoSource" icon="plus">
                Agregar fuente de video
            </c-button>
        </footer>




    </div>
</template>

<script setup>
import { defineProps, ref, onMounted, h } from 'vue'
import { onBeforeRouteLeave } from 'vue-router';
const props = defineProps({
    contentId: {
        type: String,
        required: true,
    },
    seasonId: {
        type: String,
        required: false,
        default: null,
    },
    episodeId: {
        type: String,
        required: false,
        default: null,
    },
    initialVideoSources: {
        type: Array,
        required: false,
        default: () => [],
    },
})


const videoSources = ref([])

const newVideoSource = ref({
    url: '',
    file: null,
})

const creatingVideoSource = ref(false)

const addVideoSource = () => {
    if(creatingVideoSource.value) return // Prevent clearing the newVideoSource object if the user is already creating a video source
    creatingVideoSource.value = true
    newVideoSource.value = {
        url: '',
        file: null,
    }
}

const removeVideoSource = (index) => {
    videoSources.value = videoSources.value.filter((_, i) => i !== index)
}

const saveVideoSources = () => {
    // Aquí puedes guardar las fuentes de video en la base de datos
    // Puedes usar el método `this.$http.post` para hacer una petición a tu API
    // Puedes usar el método `this.$http.put` para hacer una petición a tu API
    // Puedes usar el método `this.$http.delete` para hacer una petición a tu API
    // Puedes usar el método `this.$http.get` para hacer una petición a tu API
}

onMounted(() => {
    // Use preloaded data if available
    if (props.initialVideoSources.length > 0) {
        videoSources.value = props.initialVideoSources
    }

    console.log('Content ID:', props.contentId)
    console.log('Season ID:', props.seasonId)
    console.log('Episode ID:', props.episodeId)

    console.log('Initial Video Sources:', props.initialVideoSources)
})

onBeforeRouteLeave((to, from, next) => {
    if(creatingVideoSource.value) {
        if(confirm('Estás creando una fuente de video, ¿estás seguro que quieres salir?')) {
            creatingVideoSource.value = false
            next()
        } else {
            next(false)
        }
    } else {
        next()
    }
})
</script>