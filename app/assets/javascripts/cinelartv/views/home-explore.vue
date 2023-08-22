<template>
    <div id="home-explore">
        <div class="mx-auto mt-4">
            <div class="swiper-container" v-if="SiteSettings.enable_carousel">
                <div class="swiper-wrapper">
                    <div v-for="(slide, index) in demoCarousel" :key="index" class="swiper-slide">
                        <div class="carousel__slide">
                            <img :src="slide.image" :alt="slide.name" class="carousel__image" />
                            <!-- Image again to make a coloured shadow -->
                            <img :src="slide.image" :alt="slide.name" class="carousel__shadow" />
                            <div class="carousel__overlay">
                                <h3 class="carousel__title">{{ slide.name }}</h3>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="swiper-button-next"></div>
                <div class="swiper-button-prev"></div>
            </div>
        </div>
    </div>
</template>
  
<script setup>
import 'swiper/swiper-bundle.css';
import { ref, onMounted } from 'vue';
import Swiper from 'swiper';

import { SiteSettings } from '../pre-initializers/essentials-preload';

const demoCarousel = ref([
    {
        name: 'Avengers: Endgame',
        image: 'https://image.tmdb.org/t/p/original/7RyHsO4yDXtBv1zUU3mTpHeQ0d5.jpg',
    },
    {
        name: 'Bob Esponja: Al Rescate',
        image: 'https://www.themoviedb.org/t/p/original/o6eVlCjvxLn3Fzyr9gsYKAQNNxl.jpg',
    },
    {
        name: 'Club 57',
        image: 'https://www.themoviedb.org/t/p/original/4nTaEWva71Wcpdt1G19EEug9JqT.jpg'
    },
    {
        name: 'El Rey León',
        image: 'https://www.themoviedb.org/t/p/w500_and_h282_face/1TUg5pO1VZ4B0Q1amk3OlXvlpXV.jpg'
    }
    // Add more slides here
])

let swiper;

onMounted(() => {
    if (SiteSettings.enable_carousel) {
        swiper = new Swiper('.swiper-container', {
            effect: 'coverflow',
            slidesPerView: 2,
            autoplay: {
                delay: 5000,
            },
            centeredSlides: true,
            coverflowEffect: {
                rotate: 0, // Slide rotate in degrees
                stretch: 0, // Stretch space between slides (in px)
                depth: 100, // Depth offset in px (slides translate in Z axis)
                modifier: 1, // Effect multipler

                slideShadows: true, // Enable slide shadows
            },
            loop: true,
            loopedSlidesLimit: false,
            navigation: {
                nextEl: '.swiper-button-next',
                prevEl: '.swiper-button-prev',
            },
        });
    }

});
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
  