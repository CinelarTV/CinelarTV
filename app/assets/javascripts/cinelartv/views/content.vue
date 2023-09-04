<template>
    <div>
      <div class="mt-4 text-center" v-if="loading">
        <!-- Muestra un spinner mientras se carga el contenido -->
        <c-spinner />
      </div>
      <div v-else>
        <div class="content-overview" :data-content-id="contentData.content.id">
          <!-- Banner con overlay de info o tráiler -->
          <div class="banner-container">
            <img
              class="banner-image"
              :src="contentData.content.banner"
              alt="Banner del contenido"
              v-if="!showTrailer"
            />
            <video
              ref="trailerVideo"
              class="banner-image"
              v-else
              controls
              autoplay
            >
              <source :src="contentData.trailer" type="video/mp4" />
              Your browser does not support the video tag.
            </video>
            <div class="banner-overlay">
              <!-- Contenido del overlay, como título y descripción -->
              <h2 class="text-2xl font-bold mb-4">{{ contentData.content.title }}</h2>
              <p>{{ contentData.content.description }}</p>
            </div>
          </div>
  
          <!-- Muestra el selector de temporadas si el contenido es de tipo TVSHOW -->
          <div v-if="contentData.content.content_type === 'TVSHOW'">
            <h3 class="text-xl font-bold mt-4">Temporadas</h3>
            <ul>
              <li v-for="season in contentData.seasons" :key="season.id">
                <router-link :to="`/content/${contentData.content.id}/season/${season.id}`">
                  Temporada {{ season.number }}
                </router-link>
              </li>
            </ul>
          </div>
  
          <!-- Agrega más detalles del contenido aquí -->
        </div>
      </div>
    </div>
  </template>
  
  <script setup>
  import { onMounted, ref, watch } from 'vue'
  import { useRoute, useRouter } from 'vue-router'
  import { useHead } from 'unhead'
  import axios from 'axios'
  
  const $route = useRoute()
  const router = useRouter()
  
  const loading = ref(true)
  const contentData = ref(null)
  const showTrailer = ref(false)
  
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
  