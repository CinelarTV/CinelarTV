<template>
    <div id="home-explore">
      <div v-if="!homepage" class="mx-auto mt-4">
        <c-spinner />
      </div>
      <div class="mx-auto mt-4" v-else>
        <swiper
          v-if="SiteSettings.enable_carousel && homepage && homepage.banner_content"
          :slides-per-view="2"
          :loop="true"
          :cards-effect="{ slideShadows: false }"
          :centered-slides="true"
          :autoplay="true"
          :pagination="{ clickable: true }"
          :coverflow-effect="{ rotate: 0, stretch: 0, depth: 100, modifier: 1, slideShadows: true }"
          :grab-cursor="true"
          :auto-height="true"
          :keyboard="{ enabled: true }"
          :mousewheel="{ invert: false }"
          :breakpoints="{
            640: {
              slidesPerView: 1,
              spaceBetween: 0
            },
            768: {
              slidesPerView: 2,
              spaceBetween: 20
            },
            1024: {
              slidesPerView: 2,
              spaceBetween: 30
            }
          }"
          class="swiper-container"
          ref="swiper"
          @swiper="onSwiper"
          @slideChange="onSlideChange"
        >
          <swiper-slide v-for="slide in homepage.banner_content" :key="slide.id">
            <div class="carousel__slide">
              <img :src="slide.banner" :alt="slide.title" class="carousel__image" />
              <!-- Image again to make a coloured shadow -->
              <img :src="slide.banner" :alt="slide.title" class="carousel__shadow" />
              <div class="carousel__overlay">
                <h3 class="carousel__title">{{ slide.title }}</h3>
              </div>
            </div>
          </swiper-slide>
        </swiper>
      </div>
    </div>
  </template>
  
  <script setup>
  import 'swiper/swiper-bundle.css';
  import { ref, onMounted, getCurrentInstance, watch } from 'vue';
  import { Swiper, SwiperSlide } from 'swiper/vue';
  import { SiteSettings, homepageData } from '../pre-initializers/essentials-preload';
  
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
  
  const onSwiper = (swiper) => {
    console.log(swiper);
  };
  
  const onSlideChange = () => {
    console.log('slide change');
  };
  
  </script>
  
<style scoped>
.carousel__slide {
    position: relative;
    height: calc(100vh - 300px);
    overflow: hidden;
    transition: transform 0.5s, opacity 0.5s;
    border-radius: 16px;
    box-shadow: 0px 4px 6px rgba(0, 0, 0, 0.1);
}

.carousel__shadow {
    position: absolute;
    bottom: -10px;
    left: 20px;
    opacity: 0.5;
    filter: blur(10px);
    z-index: -1;
}

.carousel__image {
    width: 100%;
    height: 100%;
    aspect-ratio: 3/1;
    object-fit: cover;
}

.carousel__overlay {
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    padding: 16px;
    background: linear-gradient(transparent, rgba(0, 0, 0, 0.7));
    color: white;
    display: flex;
    align-items: flex-end;
    height: 40%;
}

.carousel__title {
    font-size: 1.5rem;
    margin-bottom: 8px;
}

.swiper-button-prev,
.swiper-button-next {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    width: 30px;
    height: 30px;
    background-color: rgba(0, 0, 0, 0.5);
    border-radius: 50%;
    color: white;
    display: flex;
    justify-content: center;
    align-items: center;
    cursor: pointer;
    z-index: 1;
}

.swiper-button-next {
    right: 10px;
}

.swiper-button-prev {
    left: 10px;
}

.swiper-container {
    overflow: hidden;
}

.swiper-slide-active {
    opacity: 1 !important;
    scale: 1;
    z-index: 5;
}

.swiper-slide-prev,
.swiper-slide-next {
    opacity: 0.5 !important;
    scale: 0.8;
    z-index: 2;
}
</style>
  