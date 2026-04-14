<template>
    <div class="search-page">
        <div class="search-page__container">
            <header class="search-page__header">
                <h1 class="search-page__title">Buscar</h1>
                <p class="search-page__subtitle">Encuentra películas, series y personas en CinelarTV.</p>

                <form class="search-page__searchbar" @submit.prevent="search">
                    <c-icon icon="search" class="search-page__search-icon" />

                    <input v-model="searchQuery" type="text" class="search-page__input"
                        placeholder="Buscar película, serie o persona..." autocomplete="off" autofocus />

                    <button v-if="searchQuery" type="button" class="search-page__clear" aria-label="Limpiar búsqueda"
                        @click="clearSearch">
                        <c-icon icon="x" />
                    </button>

                    <button type="submit" class="search-page__submit" aria-label="Buscar">
                        Buscar
                    </button>
                </form>

                <div class="search-page__meta">
                    <span v-if="searchQuery.length < minChars">Escribe al menos {{ minChars }} caracteres</span>
                    <span v-else-if="searching">Buscando resultados...</span>
                    <span v-else-if="hasSearched">{{ results.length }} resultados para “{{ searchQuery }}”</span>
                    <span v-else>Empieza a escribir para buscar</span>
                </div>
            </header>

            <section class="search-page__results">
                <div v-if="searching" class="search-page__loading">
                    <c-spinner />
                    <span>Buscando contenido...</span>
                </div>

                <div v-else-if="results.length > 0" class="search-page__grid">
                    <article v-for="result in results" :key="result.id" class="search-page__item">
                        <ContentCard :data="result" />
                    </article>
                </div>

                <div v-else-if="hasSearched" class="search-page__empty">
                    <c-icon icon="search" class="search-page__empty-icon" />
                    <h2>Sin resultados</h2>
                    <p>Prueba con otro título, género o nombre de persona.</p>
                </div>

                <div v-else class="search-page__placeholder">
                    <h2>Busca en todo el catálogo</h2>
                    <p>Los resultados aparecerán aquí.</p>
                </div>
            </section>
        </div>
    </div>
</template>

<script setup>
import { ref, watch, onBeforeUnmount } from 'vue';
import { ajax } from '../lib/Ajax';
import ContentCard from '../components/content-card.vue';
import cSpinner from "../components/c-spinner.tsx";
import CIcon from "../components/c-icon.vue";

const searchQuery = ref('');
const results = ref([]);
const searching = ref(false);
const hasSearched = ref(false);
const minChars = 3;
let searchDebounce = null;

const search = async () => {
    const query = searchQuery.value.trim();
    if (query.length < minChars) {
        hasSearched.value = false;
        results.value = [];
        return;
    }

    if (searching.value) return;

    searching.value = true;
    hasSearched.value = true;

    try {
        const { data } = await ajax.get('/search.json', {
            params: { query }
        });
        results.value = data.data || [];
    } catch (error) {
        console.log(error);
    } finally {
        searching.value = false;
    }
};

const clearSearch = () => {
    searchQuery.value = '';
    results.value = [];
    hasSearched.value = false;
};

watch(() => searchQuery.value, () => {
    if (searchDebounce) window.clearTimeout(searchDebounce);

    if (searchQuery.value.trim().length < minChars) {
        results.value = [];
        hasSearched.value = false;
        return;
    }

    searchDebounce = window.setTimeout(() => {
        search();
    }, 260);
});

onBeforeUnmount(() => {
    if (searchDebounce) window.clearTimeout(searchDebounce);
});
</script>