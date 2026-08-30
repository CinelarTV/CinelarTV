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

                <div class="search-page__filters" v-if="hasSearched && hasResults">
                    <button v-for="filter in typeFilters" :key="filter.value"
                        :class="['search-page__filter', { 'search-page__filter--active': activeFilter === filter.value }]"
                        @click="setFilter(filter.value)">
                        {{ filter.label }}
                    </button>
                </div>

                <div class="search-page__meta">
                    <span v-if="searchQuery.length < minChars">Escribe al menos {{ minChars }} caracteres</span>
                    <span v-else-if="searching">Buscando resultados...</span>
                    <span v-else-if="hasSearched">{{ totalResults }} resultados para "{{ searchQuery }}"</span>
                    <span v-else>Empieza a escribir para buscar</span>
                </div>
            </header>

            <section class="search-page__results">
                <div v-if="searching" class="search-page__loading">
                    <c-spinner />
                    <span>Buscando contenido...</span>
                </div>

                <template v-else-if="hasResults">
                    <div v-if="filteredContents.length > 0" class="search-page__section">
                        <h2 class="search-page__section-title">Películas y Series</h2>
                        <div class="search-page__grid">
                            <article v-for="item in filteredContents" :key="item.id" class="search-page__item">
                                <ContentCard :data="item" />
                            </article>
                        </div>
                    </div>

                    <div v-if="results.people?.length > 0 && activeFilter === 'all'" class="search-page__section">
                        <h2 class="search-page__section-title">Personas</h2>
                        <div class="search-page__people-grid">
                            <article v-for="person in results.people" :key="person.id" class="search-page__person">
                                <div class="search-page__person-avatar">
                                    <img v-if="person.profile_path" :src="person.profile_path" :alt="person.name" />
                                    <c-icon v-else icon="user" :size="32" />
                                </div>
                                <span class="search-page__person-name">{{ person.name }}</span>
                            </article>
                        </div>
                    </div>

                    <div v-if="results.categories?.length > 0 && activeFilter === 'all'" class="search-page__section">
                        <h2 class="search-page__section-title">Categorías</h2>
                        <div class="search-page__categories">
                            <span v-for="cat in results.categories" :key="cat.id" class="search-page__category">
                                {{ cat.name }}
                            </span>
                        </div>
                    </div>
                </template>

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
import { ref, computed, watch, onBeforeUnmount } from 'vue';
import { ajax } from '../lib/Ajax';
import ContentCard from '../components/content-card.vue';
import cSpinner from "../components/c-spinner.tsx";
import CIcon from "../components/c-icon.vue";

const searchQuery = ref('');
const results = ref({ contents: [], people: [], categories: [] });
const searching = ref(false);
const hasSearched = ref(false);
const activeFilter = ref('all');
const minChars = 3;
let searchDebounce = null;

const typeFilters = [
    { label: 'Todo', value: 'all' },
    { label: 'Películas', value: 'movie' },
    { label: 'Series', value: 'tvshow' }
];

const filteredContents = computed(() => {
    const contents = results.value.contents || [];
    if (activeFilter.value === 'all') return contents;
    return contents.filter(item => item.content_type === activeFilter.value.toUpperCase());
});

const hasResults = computed(() => {
    return (results.value.contents?.length > 0) ||
           (results.value.people?.length > 0) ||
           (results.value.categories?.length > 0);
});

const totalResults = computed(() => {
    const contents = activeFilter.value === 'all' ? (results.value.contents || []) : filteredContents.value;
    const people = activeFilter.value === 'all' ? (results.value.people || []) : [];
    const categories = activeFilter.value === 'all' ? (results.value.categories || []) : [];
    return contents.length + people.length + categories.length;
});

const search = async () => {
    const query = searchQuery.value.trim();
    if (query.length < minChars) {
        hasSearched.value = false;
        results.value = { contents: [], people: [], categories: [] };
        return;
    }

    if (searching.value) return;

    searching.value = true;
    hasSearched.value = true;
    activeFilter.value = 'all';

    try {
        const { data } = await ajax.get('/search.json', {
            params: { query }
        });
        results.value = {
            contents: data.data || [],
            people: data.people || [],
            categories: data.categories || []
        };
    } catch (error) {
        console.log(error);
    } finally {
        searching.value = false;
    }
};

const setFilter = (filter) => {
    activeFilter.value = filter;
};

const clearSearch = () => {
    searchQuery.value = '';
    results.value = { contents: [], people: [], categories: [] };
    hasSearched.value = false;
    activeFilter.value = 'all';
};

watch(() => searchQuery.value, () => {
    if (searchDebounce) window.clearTimeout(searchDebounce);

    if (searchQuery.value.trim().length < minChars) {
        results.value = { contents: [], people: [], categories: [] };
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
