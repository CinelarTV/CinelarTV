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