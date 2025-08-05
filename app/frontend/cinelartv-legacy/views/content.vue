<template>
  <div>
    <div class="mt-4 text-center" v-if="loading">
      <!-- Muestra un spinner mientras se carga el contenido -->
      <c-spinner />
    </div>
    <div v-else>
      <div class="content-overview" :data-content-id="contentData.id"
        :data-content-type="contentData.isMovie ? 'movie' : 'tvshow'">
        <div class="banner-wrapper" />



        <div class="content-details">
          <div class="content-title">
            <h1>{{ contentData.title }}</h1>
          </div>
          <div class="content-description">
            <p>{{ contentData.description }}</p>
          </div>
          <div class="content-actions" v-if="contentData.available">
            <c-button icon="play-circle" class="bg-blue-500 hover:bg-blue-600 text-white" @click="playContent">
              <template v-if="contentData.continueWatching">
                Continuar viendo
              </template>
              <template v-else>
                Reproducir
              </template>
            </c-button>
          </div>
          <div class="content-actions" v-else>
            <p>
              <span class="text-red-500">Este contenido no está disponible en este momento.</span>
            </p>
          </div>
          <div v-if="contentData.isTVShow">
            <div class="relative mt-16">
              <div class="panel-header flex flex-col">
                <div class="w-full flex justify-center space-x-2">
                  <template v-for="season in contentData.seasons" :key="season.id">
                    <c-button @click="toggleSeason(season.id)">
                      {{ season.title }}
                    </c-button>
                  </template>
                </div>



                <div class="panel-body">
                  <div class="episodes-list">
                    <template v-for="season in contentData.seasons" :key="season.id">
                      <div class="" v-if="season.id === activeSeason">
                        <template v-if="season.episodes.length === 0">
                          <p class="text-center">No hay episodios disponibles.</p>
                        </template>
                        <div class="season-episodes" v-else>
                          <template v-for="episode in season.episodes" :key="episode.id">
                            <div class="episode-container" @click="playEpisode(episode.id)">
                              <img :src="episode.thumbnail" class="episode-thumbnail" />
                              <div class="episode-metadata">
                                <h3 class="episode-title">
                                  {{ episode.title }}
                                </h3>
                                <p class="episode-description">
                                  {{ episode.description }}
                                </p>
                              </div>
                            </div>
                          </template>
                        </div>


                      </div>
                    </template>
                  </div>

                </div>
              </div>
            </div>


          </div>
          <div class="related-content">
            <div class="text-2xl font-bold mb-4">Talvez te guste...</div>
            <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-4">
              <template v-for="content in contentData.relatedContent" :key="content.id">
                <router-link :to="{ name: 'content.show', params: { id: content.id }, force: true }">
                  <div class="content-card">
                    <div class="content-card__image">
                      <img :src="content.cover" alt="Cover Image" />
                    </div>
                    <div class="content-card__title">
                      {{ content.title }}
                    </div>
                  </div>
                </router-link>
              </template>
            </div>
          </div>
        </div>

      </div>

      <requireSignupModal ref="requireSignupModalRef" :content-name="contentData.title"
        @openSignupModal="console.log(0)" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, watch, inject } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { PlayCircleIcon } from 'lucide-vue-next'
import { useHead } from 'unhead'
import requireSignupModal from '../components/modals/require-signup.modal.vue'
import { ajax } from '../lib/Ajax'
import Content from '../app/models/Content'
import ContentCard from '../components/content-card.vue'

const currentUser = inject('currentUser')

const $route = useRoute()
const router = useRouter()

const loading = ref(true)
const contentData = ref<Content>(null)
const showTrailer = ref(false)
const activeSeason = ref(null)
const requireSignupModalRef = ref(null)
const loginModalRef = ref(null)

const getContent = async () => {
  try {
    contentData.value = await Content.getById($route.params.id.toString())

    console.log('Contenido:', contentData.value)

    if (contentData.value?.isTVShow) {
      if (contentData.value.seasons?.length > 0) {
        activeSeason.value = contentData.value.seasons[0].id
      }
    }
    loading.value = false
    // Verificar si hay tráiler después de cargar el contenido
    if (contentData.value?.trailerUrl) {
      await preloadTrailer(contentData.value.trailerUrl)
      showTrailer.value = true
    }
  } catch (error) {
    console.error(error)
    if (error.response.status === 404) {
      // Redirige a la página de "no encontrado" si el contenido no se encuentra, pero sin cambiar la URL
      router.replace({ name: 'application.not-found' })
    }
  }
}

const toggleSeason = (seasonId) => {
  if (activeSeason.value === seasonId) {
    return
  } else {
    activeSeason.value = seasonId
  }
}

const openRequireSignupModal = () => {
  requireSignupModalRef.value.setIsOpen(true)
}

onBeforeUnmount(() => {
  document.body.classList.remove('content-route')
})

const playContent = () => {
  if (!currentUser) {
    openRequireSignupModal()
    return
  }

  if (contentData.value.isMovie) {
    router.push(`/watch/${contentData.value.id}`)
  } else {
    if (contentData.value.continueWatching) {
      router.push(`/watch/${contentData.value.id}/${contentData.value.continueWatching.episodeId}`)
      return
    }
    router.push(`/watch/${contentData.value.id}/${contentData.value.seasons[0].episodes[0].id}`)
  }
}

window.addEventListener('scroll', () => {
  if (window.scrollY > 120) {
    document.body.classList.add('scrolled')
  } else {
    document.body.classList.remove('scrolled')
  }
})


const playEpisode = (episodeId) => {
  if (!currentUser) {
    openRequireSignupModal()
    return
  }
  router.push(`/watch/${contentData.value.id}/${episodeId}`)
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
  document.body.classList.add('content-route')


  const bannerWrapper = document.querySelector('.banner-wrapper') as HTMLElement
  const image = new Image()
  image.src = contentData.value.banner

  image.addEventListener('load', () => {

    bannerWrapper.style.backgroundImage = `url(${image.src})`;
    bannerWrapper.classList.add('banner-loaded')
  })

  image.addEventListener('error', () => {
    if (contentData.value.cover) {

      bannerWrapper.style.backgroundImage = `url(${contentData.value.cover})` // Use the cover image as a fallback (if available)
    } else {
      bannerWrapper.style.backgroundImage = 'url(/assets/images/content_no_media.png)' // Use a placeholder image as a fallback
    }

    bannerWrapper.classList.add('banner-loaded')
  })
  // Configura el título y la descripción de la página para SEO
  useHead({
    title: contentData.value.title,
    meta: [
      {
        name: 'description',
        content: contentData.value?.description
      }
    ]
  })
})
</script>