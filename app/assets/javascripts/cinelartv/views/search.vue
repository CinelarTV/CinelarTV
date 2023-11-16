<template>
    <div class="search-page">
        <div class="search-page__header">
            <div class="search-page__header__title">
                <h1>Search</h1>
            </div>
            <div class="search-page__header__search">
                <c-input type="text" placeholder="Search for a movie, tv show, person..." v-model="searchQuery"
                    @keyup.enter="search" />
                <button @click="search">
                    <SearchIcon />
                </button>
            </div>
        </div>
        <div class="search-page__results">
            <div class="search-page__results__title">
                <h2>Results</h2>
            </div>
            <div v-if="searching" class="search-page__results__content__loading">
                    <c-spinner />
                </div>
            <div class="search-page__results__content" v-else>
                <div class="search-page__results__content__item" v-for="result in results" :key="result.id" v-if="results && results.length > 0">
                    <ContentCard :data="result" />
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, watch, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { ajax } from '../lib/Ajax';
import ContentCard from '../components/content-card.vue';

const searchQuery = ref('');
const results = ref([]);
const searching = ref(false);

const search = async () => {
    try {
        if (searching.value) {
            return;
        }

        searching.value = true;

        const { data } = await ajax.get('/search.json', {
            params: {
                query: searchQuery.value
            }
        });

        results.value = data.data;

    } catch (error) {
        console.log(error);
    } finally {
        searching.value = false;
    }
};

watch(() => searchQuery.value, () => {
    if (searchQuery.value.length > 2) {
        search();
    }
});


</script>../lib/ajax