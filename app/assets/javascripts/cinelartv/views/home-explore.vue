<template>
    <div id="home-explore">
        <div v-if="!homepage" class="mx-auto mt-4">
            <c-spinner />
        </div>
        <div class="mx-auto mt-4" v-else>
            <section id="home-carousel">
                <div class="carousel-root">
                    <ul class="carousel-ul">
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
                                            </div>
                                        </section>
                                    </div>
                                    <img :src="item.banner" alt="Banner Image" />
                                </div>
                            </article>
                        </li>
                    </ul>
                </div>
            </section>

            <section id="main-content">
                <template v-for="(contentArray, categoryName) in homepage.content">
                    <h3 class="text-2xl font-bold mb-4">
                        {{ categoryName }}
                    </h3>

                    <div class="carousel-root">
                        <ul class="carousel-ul content-scroll-container">
                            <li v-for="data in contentArray" :key="data.id">
                                <article>
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
import { PlayCircleIcon } from 'lucide-vue-next';
import { ref, onMounted, getCurrentInstance, inject } from 'vue';

const SiteSettings = inject('SiteSettings');
const currentUser = inject('currentUser');
const homepageData = inject('homepageData');
const { $t, $http } = getCurrentInstance().appContext.config.globalProperties;
const homepage = ref(null);
const descriptionCurrent = ref(null);

homepage.value = homepageData || null;

onMounted(async () => {
    if (!homepage.value) {
        try {
            const response = await $http.get('/explore.json');
            homepage.value = response.data;
        } catch (error) {
            console.error('Error loading data:', error);
        }
    }
});
</script>

<style scoped>
/* Add this to your existing CSS or a dedicated CSS file */
#main-content .content-scroll-container {
    display: flex;
    overflow-x: auto;
    /* Enable horizontal scrolling */
    padding-bottom: 20px;
    /* Add some spacing at the bottom */
}

#main-content .content-items {
    flex: 0 0 auto;
    /* Allow the items to take up their natural width */
    margin-right: 10px;
    /* Add spacing between items */
}

#main-content .content-items:last-child {
    margin-right: 0;
    /* Remove spacing from the last item */
}

.content-card {
    --border-radius: 8px;
    background-color: #33373d;
    border-bottom-left-radius: var(--border-radius);
    border-bottom-right-radius: var(--border-radius);
    border-top-left-radius: var(--border-radius);
    border-top-right-radius: var(--border-radius);
    max-height: 80px;
}
</style>