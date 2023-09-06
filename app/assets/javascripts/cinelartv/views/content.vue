<template>
  <div>
    <div class="mt-4 text-center" v-if="loading">
      <!-- Muestra un spinner mientras se carga el contenido -->
      <c-spinner />
    </div>
    <div v-else>
      <div class="content-overview" :data-content-id="contentData.content.id">
        <div class="banner-wrapper" />



        <div class="content-details">
          <div class="content-title">
            <h1>{{ contentData.content.title }}</h1>
          </div>
          <div class="content-description">
            <p>{{ contentData.content.description }}</p>
          </div>
          <div class="content-actions" v-if="contentData.content.available">
            <c-button :icon="PlayCircleIcon" class="bg-blue-500 hover:bg-blue-600 text-white" @click="playContent">
              Reproducir
            </c-button>
          </div>
          <div class="content-actions" v-else>
            <p>
              <span class="text-red-500">Este contenido no está disponible en este momento.</span>
            </p>
          </div>
        </div>

        <!-- Agrega más detalles del contenido aquí -->
      </div>
    </div>
  </div>
</template>
  
<script setup>
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { PlayCircleIcon } from 'lucide-vue-next'
import { useHead } from 'unhead'
import axios from 'axios'

const $route = useRoute()
const router = useRouter()

const loading = ref(true)
const contentData = ref(null)
const showTrailer = ref(false)

document.body.classList.add('content-route')

const getContent = async () => {
  try {
    const { data } = await axios.get(`/contents/${$route.params.id}.json`)
    contentData.value = data
    loading.value = false
    // Verificar si hay tráiler después de cargar el contenido
    if (contentData.value.trailer) {
      await preloadTrailer(contentData.value.trailer)
      showTrailer.value = true
    }
  } catch (error) {
    console.error(error)
    if (error.response.status === 404) {
      // Redirige a la página de "no encontrado" si el contenido no se encuentra
      router.replace({ name: 'application.not-found', replace: true })
    }
  }
}

onBeforeUnmount(() => {
  document.body.classList.remove('content-route')
})

const preloadTrailer = async (trailerSrc) => {
  // Pre-cargar el tráiler para mejorar la experiencia del usuario
  const video = document.createElement('video');
  video.src = trailerSrc;
  console.log('Pre-cargando tráiler...');
  console.log('Tráiler:', trailerSrc);

  video.addEventListener('loadeddata', () => {
    console.log('Tráiler pre-cargado con éxito.');
  });

  video.addEventListener('error', (e) => {
    console.error('Error al pre-cargar el tráiler:', e);
  });

  await video.load();
}


onMounted(async () => {
  await getContent()

  const bannerWrapper = document.querySelector('.banner-wrapper')
  const image = new Image()
  image.src = contentData.value.content.banner

  image.addEventListener('load', () => {
    bannerWrapper.style.backgroundImage = `url(${image.src})`
    bannerWrapper.classList.add('banner-loaded')
  })

  // Configura el título y la descripción de la página para SEO
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
  
  <!-- Estilos CSS (puedes personalizarlos) -->
<style scoped>
.banner-container {
  position: relative;
}

.banner-image {
  width: 100%;
  height: calc(100vh - 16vh);
  object-fit: cover;
  object-position: center;
}

.banner-overlay {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.6);
  color: #fff;
  padding: 20px;
  display: flex;
  flex-direction: column;
  justify-content: flex-end;
}
</style>
  