<template>
    <div id="home-explore">
        <div v-if="!homepage" class="mx-auto mt-4">
            <c-spinner />
        </div>
        <div class="mx-auto mt-4" v-else>
            <section id="home-carousel">
                <div class="carousel-root">
                    <ul class="carousel-ul" ref="carouselContainer" @scroll="handleScroll" @mouseenter="stopAutoScroll" @mouseleave="startAutoScroll">
                        <li v-for="item in homepage.banner_content" :key="item.id">
                            <article class="standard-hero-card">
                                <div class="standard-hero-card__image">
                                    <div class="carousel-overlay">
                                        <section class="carousel-banner-info">
                                            <h2 class="text-2xl">
                                                {{ item.title }}
                                            </h2>

                                            <p class="text-sm py-2">
                                                {{ item.description }}
                                            </p>

                                            <div class="standard-hero-card__actions">
                                                <c-button @click="playContent(item.id)">
                                                    <PlayCircleIcon class="icon" :size="18" />
                                                    Reproducir ahora
                                                </c-button>

                                                <c-button @click="addToCollection(item.id)">
                                                    <PlusIcon class="icon" :size="18" />
                                                    Mi Colección
                                                </c-button>

                                                <c-icon-button :icon="InfoIcon" @click="showInfo(item.id)" />
                                            </div>
                                        </section>
                                    </div>
                                    <img :src="item.banner" alt="Banner Image" />
                                </div>
                            </article>
                        </li>
                    </ul>

                </div>
                <ul class="carousel-indicators">
                    <li v-for="(item, index) in homepage.banner_content" :key="item.id"
                        :class="{ active: index === bannerCurrentIndex }" @click="scrollToSlide(index)"></li>
                </ul>
            </section>

            <section id="main-content">
                <template v-for="(contentArray, categoryName) in homepage.content">
                    <h3 class="text-2xl font-bold mb-4">
                        {{ categoryName }}
                    </h3>

                    <div class="recyclerview">
                        <ul>
                            <li v-for="data in contentArray" :key="data.id" class="content-item">
                                <article class="recyclerview-card-article">
                                    <div class="content-card">
                                        <img :src="data.banner" alt="Cover Image" />
                                    </div>
                                </article>
                            </li>
                        </ul>
                    </div>
                </template>
            </section>
        </div>
    </div>
</template>

  
<script setup>
import { PlusIcon } from 'lucide-vue-next';
import { InfoIcon } from 'lucide-vue-next';
import { PlayCircleIcon } from 'lucide-vue-next';
import { ref, onMounted, getCurrentInstance, inject } from 'vue';
import { useRouter } from 'vue-router';

const SiteSettings = inject('SiteSettings');
const currentUser = inject('currentUser');
const homepageData = inject('homepageData');
const { $t, $http } = getCurrentInstance().appContext.config.globalProperties;
const homepage = ref(null);
const descriptionCurrent = ref(null);
const carouselContainer = ref(null);
const bannerCurrentIndex = ref(0); // Define bannerCurrentIndex here
let intervalId = null;
const router = useRouter();


homepage.value = homepageData || null;

const showInfo = (id) => {
    //navigate to content page with transition
    router.push({
        name: 'content.show',
        params: {
            id: id,
        },
        meta: {
            transition: 'slide-left',
        },
    });
};

const startAutoScroll = () => {
    intervalId = setInterval(() => {
        scrollToNextSlide();
    }, 8000);
};

const stopAutoScroll = () => {
    clearInterval(intervalId);
    intervalId = null;
};

const scrollToNextSlide = () => {
    const container = carouselContainer.value;
    if (container) {
        const slideWidth = container.offsetWidth;
        const scrollOffset = slideWidth * (bannerCurrentIndex.value + 1);

        container.scrollTo({
            left: scrollOffset,
            behavior: 'smooth', // Use smooth scrolling animation
        });

        // Update bannerCurrentIndex to loop back to the first slide if at the last slide
        bannerCurrentIndex.value = (bannerCurrentIndex.value + 1) % homepage.value.banner_content.length;
    }
};

const scrollToPreviousSlide = () => {
    const container = carouselContainer.value;
    if (container) {
        const slideWidth = container.offsetWidth;
        const scrollOffset = slideWidth * (bannerCurrentIndex.value - 1);

        container.scrollTo({
            left: scrollOffset,
            behavior: 'smooth', // Use smooth scrolling animation
        });

        // Update bannerCurrentIndex to loop back to the last slide if at the first slide
        const lastIndex = homepage.value.banner_content.length - 1;
        bannerCurrentIndex.value = (bannerCurrentIndex.value - 1 + lastIndex) % homepage.value.banner_content.length;
    }
};

const scrollToSlide = (index) => {
    const container = carouselContainer.value;
    if (container) {
        const slideWidth = container.offsetWidth;
        const scrollOffset = slideWidth * index;

        container.scrollTo({
            left: scrollOffset,
            behavior: 'smooth', // Use smooth scrolling animation
        });

        // Update bannerCurrentIndex to loop back to the last slide if at the first slide
        const lastIndex = homepage.value.banner_content.length - 1;
        bannerCurrentIndex.value = index;
        stopAutoScroll();
        startAutoScroll(); // Restart auto scroll after manually scrolling
    }
};

const handleScroll = () => {
  const container = carouselContainer.value;
  if (container) {
    const slideWidth = container.offsetWidth;
    const scrollOffset = container.scrollLeft;

    // Update bannerCurrentIndex based on the scroll position
    bannerCurrentIndex.value = Math.round(scrollOffset / slideWidth);
  }
};


onMounted(async () => {
    if (!homepage.value) {
        try {
            const response = await $http.get('/explore.json');
            homepage.value = response.data;
        } catch (error) {
            console.error('Error loading data:', error);
        }
    }

    startAutoScroll();
});
</script>