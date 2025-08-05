<template>
    <div id="home-explore">
        <!-- Loading state -->
        <div v-if="loading" class="mx-auto mt-4">
            <c-spinner />
        </div>

        <!-- Main content -->
        <div v-else-if="homepage" class="mx-auto mt-4">
            <!-- Carousel section -->
            <section v-if="shouldShowCarousel" id="home-carousel">
                <!-- Navigation arrows (currently disabled) -->
                <div v-if="false" class="carousel-control-arrows">
                    <button class="carousel-arrow carousel-arrow-left" @click="scrollToPreviousSlide"
                        :disabled="bannerCurrentIndex === 0" :class="{ 'hidden': bannerCurrentIndex === 0 }"
                        aria-label="Slide anterior">
                        <c-icon-button icon="chevron-left" />
                    </button>
                    <div class="w-full">-</div>
                    <button class="carousel-arrow carousel-arrow-right" @click="scrollToNextSlide"
                        :disabled="bannerCurrentIndex >= bannerItems.length - 1"
                        :class="{ 'hidden': bannerCurrentIndex >= bannerItems.length - 1 }"
                        aria-label="Siguiente slide">
                        <c-icon-button icon="chevron-right" />
                    </button>
                </div>

                <!-- Carousel container -->
                <div class="carousel-root">
                    <ul class="carousel-ul" ref="carouselContainer" @scroll="handleScroll" @mouseenter="pauseAutoScroll"
                        @mouseleave="resumeAutoScroll" role="region" aria-label="Banner carousel">
                        <li v-for="(item, index) in bannerItems" :key="item.id">
                            <article class="standard-hero-card" :aria-label="`Banner ${index + 1}: ${item.title}`">
                                <div class="standard-hero-card__image">
                                    <div class="carousel-overlay">
                                        <section class="carousel-banner-info">
                                            <h2 class="text-2xl">{{ item.title }}</h2>
                                            <p class="text-sm py-2">{{ item.description }}</p>

                                            <div class="standard-hero-card__actions">
                                                <c-button @click="playContent(item.id)" icon="play-circle"
                                                    aria-label="Reproducir ahora">
                                                    Reproducir ahora
                                                </c-button>

                                                <c-button @click="addToCollection(item.id)" icon="plus"
                                                    aria-label="Agregar a mi colección">
                                                    Mi Colección
                                                </c-button>

                                                <c-icon-button icon="info" @click="showInfo(item.id)"
                                                    aria-label="Ver información" />

                                                <c-icon-button icon="thumbs-up"
                                                    :class="{ '!text-blue-500': item.liked }"
                                                    @click="toggleLike(item.id, true)"
                                                    :aria-label="item.liked ? 'Quitar de favoritos' : 'Agregar a favoritos'" />
                                            </div>
                                        </section>
                                    </div>
                                    <img :src="item.banner" :alt="`Banner de ${item.title}`" loading="lazy" />
                                </div>
                            </article>
                        </li>
                    </ul>
                </div>

                <!-- Carousel indicators -->
                <ul class="carousel-indicators" role="tablist" aria-label="Indicadores de carousel">
                    <li v-for="(item, index) in bannerItems" :key="`indicator-${item.id}`"
                        :class="{ active: index === bannerCurrentIndex }" @click="scrollToSlide(index)" role="tab"
                        :aria-selected="index === bannerCurrentIndex" :aria-label="`Ir al slide ${index + 1}`"></li>
                </ul>
            </section>

            <!-- Content sections -->
            <section id="main-content">
                <template v-for="category in contentCategories" :key="category.title">
                    <h3 class="text-2xl font-bold mt-8 mb-2 ml-6">
                        {{ category.title }}
                    </h3>

                    <div v-if="category.content?.length" class="recyclerview">
                        <ul>
                            <ContentCard v-for="item in category.content" :key="item.id" :data="item"
                                class="content-item" />
                        </ul>
                    </div>
                    <div v-else class="ml-6 text-gray-500">
                        No hay contenido disponible en esta categoría.
                    </div>
                </template>
            </section>
        </div>

        <!-- Empty state -->
        <div v-else class="flex justify-center items-center mt-8">
            <p>No se pudo cargar el contenido. Intenta recargar la página.</p>
        </div>

        <!-- Footer message -->
        <div class="flex justify-center items-center mt-4 py-8">
            <c-icon icon="award" class="text-4xl mr-2" size="24" />
            <p>Esto es todo por ahora. ¡Vuelve pronto para más contenido!</p>
        </div>
    </div>
</template>


<script setup>
import { ref, computed, onMounted, onBeforeUnmount, inject, getCurrentInstance } from 'vue'
import { useRouter } from 'vue-router'
import { useHead } from 'unhead'
import { toast } from 'vue3-toastify'
import { ajax } from '../lib/Ajax'
import ContentCard from '../components/content-card.vue'

// Injected dependencies
const SiteSettings = inject('SiteSettings')
const currentUser = inject('currentUser')
const homepageData = inject('homepageData')
const { $t } = getCurrentInstance().appContext.config.globalProperties

// Router
const router = useRouter()

// Reactive state
const homepage = ref(null)
const carouselContainer = ref(null)
const bannerCurrentIndex = ref(0)
const loading = ref(true)
const autoScrollInterval = ref(null)
const isUserInteracting = ref(false)

// Constants
const AUTO_SCROLL_DELAY = 8000
const SCROLL_DEBOUNCE_DELAY = 100

// Computed properties
const shouldShowCarousel = computed(() => {
    return SiteSettings?.enable_carousel && bannerItems.value.length > 0
})

const bannerItems = computed(() => {
    return homepage.value?.banner_content || []
})

const contentCategories = computed(() => {
    return homepage.value?.content || []
})

// Head configuration
useHead({
    title: 'Explorar',
    meta: [
        {
            name: 'description',
            content: SiteSettings?.site?.description || 'Explora contenido',
        },
    ],
})

// Navigation methods
const showInfo = (id) => {
    router.push({
        name: 'content.show',
        params: { id },
        meta: { transition: 'slide-left' },
    })
}

const playContent = (id) => {
    router.push({
        path: `/watch/${id}`,
        meta: { transition: 'slide-left' },
    })
}

const addToCollection = async (id) => {
    if (!currentUser) {
        toast.error($t('js.user.login_required'))
        return
    }

    try {
        await ajax.post(`/contents/${id}/add-to-collection.json`)
        toast.success($t('js.user.added_to_collection'))
    } catch (error) {
        console.error('Error adding to collection:', error)
        toast.error($t('js.user.collection_error'))
    }
}

// Like/Unlike functionality
const toggleLike = async (id, fromBanner = false) => {
    if (!currentUser) {
        toast.error($t('js.user.login_required'))
        return
    }

    try {
        const targetArray = fromBanner ? bannerItems.value : contentCategories.value.flatMap(cat => cat.content || [])
        const content = targetArray.find((item) => item.id === id)

        if (!content) {
            console.error(`Content with id ${id} not found`)
            return
        }

        const endpoint = content.liked ? 'unlike' : 'like'
        await ajax.post(`/contents/${id}/${endpoint}.json`)

        content.liked = !content.liked
        toast.success(content.liked ? $t('js.user.added_to_favorites') : $t('js.user.removed_from_favorites'))

    } catch (error) {
        console.error('Error toggling like:', error)
        toast.error($t('js.user.like_error'))
    }
}

// Carousel functionality
let scrollDebounceTimer = null

const startAutoScroll = () => {
    if (autoScrollInterval.value || isUserInteracting.value || bannerItems.value.length <= 1) {
        return
    }

    autoScrollInterval.value = setInterval(() => {
        if (!isUserInteracting.value && shouldShowCarousel.value) {
            scrollToNextSlide()
        }
    }, AUTO_SCROLL_DELAY)
}

const stopAutoScroll = () => {
    if (autoScrollInterval.value) {
        clearInterval(autoScrollInterval.value)
        autoScrollInterval.value = null
    }
}

const pauseAutoScroll = () => {
    isUserInteracting.value = true
    stopAutoScroll()
}

const resumeAutoScroll = () => {
    isUserInteracting.value = false
    setTimeout(startAutoScroll, 1000) // Small delay before resuming
}

const scrollToSlide = (index) => {
    if (index < 0 || index >= bannerItems.value.length) return

    pauseAutoScroll()

    const container = carouselContainer.value
    if (!container) return

    const slideWidth = container.offsetWidth
    const scrollOffset = slideWidth * index

    container.scrollTo({
        left: scrollOffset,
        behavior: 'smooth',
    })

    bannerCurrentIndex.value = index
    resumeAutoScroll()
}

const scrollToNextSlide = () => {
    const nextIndex = (bannerCurrentIndex.value + 1) % bannerItems.value.length
    scrollToSlide(nextIndex)
}

const scrollToPreviousSlide = () => {
    const prevIndex = (bannerCurrentIndex.value - 1 + bannerItems.value.length) % bannerItems.value.length
    scrollToSlide(prevIndex)
}

const handleScroll = () => {
    const container = carouselContainer.value
    if (!container) return

    // Debounce scroll events
    if (scrollDebounceTimer) {
        clearTimeout(scrollDebounceTimer)
    }

    scrollDebounceTimer = setTimeout(() => {
        const slideWidth = container.offsetWidth
        const scrollOffset = container.scrollLeft
        const newIndex = Math.round(scrollOffset / slideWidth)

        if (newIndex !== bannerCurrentIndex.value && newIndex >= 0 && newIndex < bannerItems.value.length) {
            bannerCurrentIndex.value = newIndex
        }
    }, SCROLL_DEBOUNCE_DELAY)
}

// Data loading
const loadHomepageData = async () => {
    try {
        loading.value = true
        const response = await ajax.get('/explore.json')
        homepage.value = response.data
    } catch (error) {
        console.error('Error loading homepage data:', error)
        toast.error('Error al cargar el contenido')
    } finally {
        loading.value = false
    }
}

// Lifecycle hooks
onMounted(async () => {
    // Use preloaded data if available, otherwise fetch
    if (homepageData?.value) {
        homepage.value = homepageData.value
        loading.value = false
        // Clear preloaded data to free memory
        if (homepageData.value) {
            homepageData.value = null
        }
    } else {
        await loadHomepageData()
    }

    // Start auto scroll if carousel is enabled
    if (shouldShowCarousel.value) {
        startAutoScroll()
    }
})

onBeforeUnmount(() => {
    stopAutoScroll()
    if (scrollDebounceTimer) {
        clearTimeout(scrollDebounceTimer)
    }
})
</script>