<template>
  <div class="not-found-page">
    <div class="not-found-page__bg-shape not-found-page__bg-shape--one" aria-hidden="true" />
    <div class="not-found-page__bg-shape not-found-page__bg-shape--two" aria-hidden="true" />

    <div class="not-found-page__container">
      <section class="not-found-page__hero">
        <div class="not-found-page__status">
          <c-icon icon="frown" :size="16" />
          <span>Error 404</span>
        </div>

        <h1 class="not-found-page__title">Esta pagina no existe o fue movida.</h1>
        <p class="not-found-page__description">
          No encontramos lo que buscabas, pero tienes muchas otras historias para descubrir.
        </p>

        <div class="not-found-page__actions">
          <router-link to="/" class="button not-found-page__home-link">
            <c-icon icon="home" :size="16" />
            Volver al inicio
          </router-link>

          <c-button icon="rotate-cw" class="not-found-page__retry-btn" @click="retryRoute">
            Reintentar
          </c-button>
        </div>
      </section>

      <section class="not-found-page__recommendations" data-recommended-contents>
        <div class="not-found-page__recommendations-header">
          <h2>Mientras tanto, te recomendamos ver</h2>
          <p>Una seleccion rapida para que sigas mirando sin perder tiempo.</p>
        </div>

        <div v-if="loadingRecommendations" class="not-found-page__state">
          <c-icon icon="loader" :size="20" class="not-found-page__spinner" />
          <span>Cargando recomendaciones...</span>
        </div>

        <div v-else-if="recommendedContents.length" class="not-found-page__grid">
          <article v-for="content in recommendedContents" :key="content.id" class="not-found-page__item">
            <ContentCard :data="content" />
          </article>
        </div>

        <div v-else class="not-found-page__state not-found-page__state--empty">
          <c-icon icon="search" :size="20" />
          <span>No pudimos cargar sugerencias por ahora.</span>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ajax } from '../../lib/Ajax'
import ContentCard from '../../components/content-card.vue'
import CIcon from '../../components/c-icon.vue'
import CButton from '../../components/forms/c-button'

const recommendedContents = ref([])
const loadingRecommendations = ref(false)

const loadRecommendations = async () => {
  loadingRecommendations.value = true

  try {
    const response = await ajax.get('/404-content.json')
    recommendedContents.value = response?.data?.contents || []
  } catch {
    recommendedContents.value = []
  } finally {
    loadingRecommendations.value = false
  }
}

const retryRoute = () => {
  if (typeof window === 'undefined') return

  const currentUrl = `${window.location.pathname}${window.location.search}${window.location.hash}`
  window.location.replace(currentUrl)
}

onMounted(() => {
  loadRecommendations()
})
</script>