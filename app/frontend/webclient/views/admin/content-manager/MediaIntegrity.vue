<template>
  <div class="panel media-integrity-page">
    <header class="admin-dashboard-page__hero">
      <p class="admin-dashboard-page__eyebrow">Content Manager</p>
      <h1 class="admin-dashboard-page__title">Integridad de Medios</h1>
      <p class="admin-dashboard-page__subtitle">
        Listado de películas y episodios cuyos links o archivos han fallado las pruebas de integridad.
      </p>
    </header>

    <section class="dashboard-card">
      <div class="flex justify-between items-center mb-6">
        <div class="section-title">
          <h2>Fuentes con Problemas</h2>
        </div>
        <div class="flex gap-2">
          <c-button @click="fetchBrokenSources" :disabled="loading" icon="rotate-cw">Refrescar</c-button>
        </div>
      </div>

      <c-spinner v-if="loading" />
      
      <div v-else-if="brokenSources.length === 0" class="flex flex-col items-center justify-center py-12 text-gray-400">
        <c-icon icon="check-circle" :size="48" class="text-green-500 mb-4" />
        <p class="text-xl">¡Excelente! No se han detectado medios rotos.</p>
      </div>

      <div v-else class="overflow-x-auto">
        <table class="w-full text-left admin-table">
          <thead>
            <tr>
              <th>Contenido / Episodio</th>
              <th>Calidad</th>
              <th>Formato</th>
              <th>Fallos</th>
              <th>Última Revisión</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="source in brokenSources" :key="source.id">
              <td>
                <div class="flex flex-col">
                  <span class="font-medium">{{ source.parent_title }}</span>
                  <span class="text-xs text-gray-500">{{ source.videoable_type }}</span>
                </div>
              </td>
              <td>{{ source.quality }}</td>
              <td>{{ source.format }}</td>
              <td>
                <span class="px-2 py-1 rounded text-xs bg-red-900 text-red-100">
                  {{ source.failure_count }} fallos
                </span>
              </td>
              <td>{{ formatDate(source.last_checked_at) }}</td>
              <td>
                <div class="flex gap-2">
                  <c-button size="small" variant="primary" @click="editContent(source)">Editar</c-button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref, onMounted, inject } from 'vue'
import { useRouter } from 'vue-router'
import { ajax } from '../../../lib/Ajax'

const router = useRouter()
const loading = ref(false)
const brokenSources = ref([])

const fetchBrokenSources = async () => {
  loading.value = true
  try {
    const response = await ajax.get('/admin/video_sources/broken.json')
    brokenSources.value = response.data.video_sources
  } catch (error) {
    console.error('Error fetching broken sources:', error)
  } finally {
    loading.value = false
  }
}

const formatDate = (dateString) => {
  if (!dateString) return 'Nunca'
  return new Date(dateString).toLocaleString()
}

const editContent = (source) => {
  if (source.videoable_type === 'Content') {
    router.push(`/admin/content-manager/${source.videoable_id}/edit`)
  } else if (source.videoable_type === 'Episode') {
    // Para episodios, solemos necesitar el contentId. 
    // Por simplicidad en este MVP, redirigimos al editor de contenido o podrías extender el API.
    // CinelarTV suele manejar episodios dentro del manager de temporadas.
    alert('Edita este episodio desde el administrador de temporadas del contenido correspondiente.')
  }
}

onMounted(() => {
  fetchBrokenSources()
})
</script>

<style scoped>
.admin-table {
  border-collapse: separate;
  border-spacing: 0 0.5rem;
}

.admin-table th {
  padding: 1rem;
  font-weight: 600;
  color: var(--c-primary-100);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.admin-table td {
  padding: 1rem;
  background: rgba(255, 255, 255, 0.05);
}

.admin-table tr:hover td {
  background: rgba(255, 255, 255, 0.1);
}
</style>
