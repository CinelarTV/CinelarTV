<template>
    <div id="home-explore">
        <div v-if="!homepage" class="mx-auto mt-4">
            <c-spinner />
        </div>
        <div class="mx-auto mt-4" v-else>
            <section id="home-carousel" v-if="SiteSettings.enable_carousel">
                <div class="carousel-root">
                    <ul class="carousel-ul" ref="carouselContainer" @scroll="handleScroll" @mouseenter="stopAutoScroll"
                        @mouseleave="startAutoScroll">
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
                                                <c-button @click="playContent(item.id)" icon="play-circle">
                                                    Reproducir ahora
                                                </c-button>

                                                <c-button @click="addToCollection(item.id)" icon="plus">
                                                    Mi Colección
                                                </c-button>

                                                <c-icon-button icon="info" @click="showInfo(item.id)" />

                                                <c-icon-button icon="thumbs-up" :class="item.liked ? '!text-blue-500' : ''"
                                                    @click="toggleLike(item.id, true)" />
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
                <template v-for="category in homepage.content">
                    <h3 class="text-2xl font-bold mt-8 mb-2 ml-6">
                        {{ category.title }}
                    </h3>

                    <div class="recyclerview" v-if="category.content">
                        <ul>
                            <ContentCard :data="data" v-for="data in category.content" :key="data.id"
                                class="content-item" />
                        </ul>
                    </div>
                </template>
            </section>
        </div>
    </div>
</template>

  
<script setup>
import { ref, onMounted, getCurrentInstance, inject } from 'vue';
import { useRouter } from 'vue-router';
import { useHead } from 'unhead';
import { toast } from 'vue3-toastify';
import { ajax } from '../lib/axios-setup';
import ContentCard from '../components/content-card.vue';

const SiteSettings = inject('SiteSettings');
const currentUser = inject('currentUser');
const homepageData = inject('homepageData');
const { $t } = getCurrentInstance().appContext.config.globalProperties;
const homepage = ref(null);
const descriptionCurrent = ref(null);
const carouselContainer = ref(null);
const bannerCurrentIndex = ref(0); // Define bannerCurrentIndex here
let intervalId = null;
const router = useRouter();


useHead({
    title: 'Explorar',
    meta: [
        {
            name: 'description',
            content: SiteSettings.value?.site?.description,
        },
    ],
});


homepage.value = homepageData.value || null;

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

const playContent = (id) => {
    router.push(`/watch/${id}`, {
        params: {
            id: id,
        },
        meta: {
            transition: 'slide-left',
        },
    });
};

const toggleLike = async (id, fromBanner = false) => {
    if (currentUser) {
        let content;
        const targetArray = fromBanner ? homepage.value.banner_content : homepage.value.content;

        content = targetArray.find((item) => item.id === id);

        if (content) {
            try {
                if (content.liked) {
                    await ajax.post(`/contents/${id}/unlike.json`);
                    toast.success($t('js.user.removed_from_favorites'));
                } else {
                    await ajax.post(`/contents/${id}/like.json`);
                    toast.success($t('js.user.added_to_favorites'));
                }
                content.liked = !content.liked; // Toggle the liked state after the request is successful
            } catch (error) {
                console.error(error); // Log the error for debugging
                toast.error($t('js.user.like_error'));
            }
        } else {
            console.error(`Content with id ${id} not found`);
        }
    } else {
        toast.error($t('js.user.login_required'));
    }
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
            const response = await ajax.get('/explore.json');
            homepage.value = response.data;
        } catch (error) {
            console.error('Error loading data:', error);
        }
    } else {
        homepageData.value = null; // Clear after load preloaded data
    }

    if (SiteSettings.enable_carousel) {
        startAutoScroll();
    }
});
</script>