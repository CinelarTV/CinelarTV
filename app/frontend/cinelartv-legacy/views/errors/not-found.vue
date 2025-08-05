<template>
  <!-- Tailwind -->
  <div class="flex flex-col items-center justify-center h-screen">
    <div class="flex flex-col items-center justify-center">
      <h1 class="text-6xl font-bold text-gray-700">404</h1>
      <h2 class="text-2xl font-semibold text-gray-600">Page not found</h2>
      <p class="text-gray-500">Sorry, we couldn't find the page you're looking for.</p>
      <p class="text-gray-500">Please try again or go back to the homepage.</p>
      <router-link to="/" class="mt-4 px-4 py-2 bg-gray-700 text-white rounded hover:bg-gray-600">Go back to homepage</router-link>
    </div>
    <div data-recommended-contents>
      Mientras tanto, te recomendamos ver:

      (Grid)

      <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4" v-if="errorData">
        <template v-for="content in errorData">
          <ContentCard :data="content" />
        </template>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ajax } from '../../lib/Ajax'
import ContentCard from '../../components/content-card.vue'

const errorData = ref(null)

onMounted(() => {
  ajax.get('/404-content.json')
    .then((response) => {
      errorData.value = response.data.contents
      console.log(response)
    })
    .catch((error) => {
      console.log(error)
    })
})

</script>../../lib/ajax