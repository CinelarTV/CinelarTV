<template>
    <div class="search-page min-h-screen bg-gradient-to-br from-indigo-900 via-gray-900 to-black py-12 px-2">
        <div class="search-page__header flex flex-col items-center justify-center mb-10">
            <div class="search-page__header__title mb-2">
                <h1 class="text-4xl font-extrabold text-white tracking-tight drop-shadow-lg">Buscar</h1>
                <p class="text-gray-300 text-base mt-2">Encuentra películas, series o personas en CinelarTV</p>
            </div>
            <div
                class="search-page__header__search flex flex-row items-center w-full max-w-2xl mt-6 bg-white/10 rounded-full shadow-lg px-4 py-2">
                <c-input type="text" placeholder="Buscar película, serie, persona..." v-model="searchQuery"
                    class="flex-1 bg-transparent text-white placeholder-gray-400 border-none focus:ring-0 text-lg"
                    @keyup.enter="search" autofocus />
                <button
                    class="ml-2 p-2 rounded-full bg-indigo-600 hover:bg-indigo-700 transition-colors text-white shadow"
                    @click="search" aria-label="Buscar">
                    <SearchIcon class="w-6 h-6" />
                </button>
            </div>
        </div>
        <div class="search-page__results max-w-6xl mx-auto">
            <div class="search-page__results__title mb-4">
                <h2 class="text-xl font-semibold text-white tracking-wide">Resultados</h2>
            </div>
            <div v-if="searching"
                class="search-page__results__content__loading flex flex-col items-center justify-center h-64">
                <c-spinner />
                <span class="text-gray-400 mt-4">Buscando...</span>
            </div>
            <div v-else class="search-page__results__content grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
                <div v-if="results && results.length > 0" class="search-page__results__content__item"
                    v-for="result in results" :key="result.id">
                    <ContentCard :data="result" />
                </div>
                <div v-else class="col-span-full text-center text-gray-400 py-12 text-lg">
                    No se encontraron resultados.
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, watch } from 'vue';
import { ajax } from '../lib/Ajax';
import ContentCard from '../components/content-card.vue';


import CInput from "../components/forms/c-input.vue";
import cSpinner from "../components/c-spinner";
import CIcon from "../components/c-icon.vue";

const searchQuery = ref('');
const results = ref([]);
const searching = ref(false);

const search = async () => {
    if (searching.value) return;
    searching.value = true;
    try {
        const { data } = await ajax.get('/search.json', {
            params: { query: searchQuery.value }
        });
        results.value = data.data;
    } catch (error) {
        console.log(error);
    } finally {
        searching.value = false;
    }
};

watch(() => searchQuery.value, () => {
    if (searchQuery.value.length > 2) search();
});
</script>