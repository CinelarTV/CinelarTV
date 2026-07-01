<template>
    <div class="max-w-5xl mx-auto px-4 sm:px-6 md:px-8 py-8">
        <!-- Header -->
        <div class="mb-8">
            <div class="flex items-center gap-4 mb-2">
                <button @click="router.back()" class="p-2 rounded-lg bg-white/5 hover:bg-white/10 transition-colors">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none"
                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                        class="w-5 h-5">
                        <polyline points="15 18 9 12 15 6" />
                    </svg>
                </button>
                <div>
                    <h1 class="text-2xl md:text-3xl font-bold text-white">
                        Integridad de Medios
                    </h1>
                    <p class="text-sm text-white/60 mt-1">
                        Peliculas y episodios con links o archivos que fallaron en pruebas de integridad.
                    </p>
                </div>
            </div>
        </div>

        <!-- Content -->
        <div class="bg-white/5 rounded-xl p-6 ring-1 ring-white/10">
            <!-- Toolbar -->
            <div class="flex items-center justify-between mb-6">
                <h2 class="text-lg font-semibold text-white">
                    Fuentes con Problemas
                </h2>
                <button
                    @click="fetchBrokenSources"
                    :disabled="loading"
                    class="flex items-center gap-2 px-3 py-2 rounded-lg bg-white/5 hover:bg-white/10 text-white/80 text-sm font-medium transition-colors ring-1 ring-white/10 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                    <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none"
                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                        :class="{ 'animate-spin': loading }">
                        <path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.2" />
                    </svg>
                    Refrescar
                </button>
            </div>

            <!-- Loading -->
            <div v-if="loading" class="flex items-center justify-center py-12">
                <div class="flex flex-col items-center gap-3">
                    <div class="animate-spin rounded-full h-10 w-10 border-2 border-white/20 border-t-white/80"></div>
                    <p class="text-white/50 text-sm">Cargando fuentes...</p>
                </div>
            </div>

            <!-- Empty State -->
            <div v-else-if="brokenSources.length === 0" class="text-center py-12">
                <div class="w-14 h-14 mx-auto mb-4 bg-green-500/10 rounded-full flex items-center justify-center">
                    <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none"
                        stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                        class="text-green-400">
                        <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
                        <polyline points="22 4 12 14.01 9 11.01" />
                    </svg>
                </div>
                <h3 class="text-base font-medium text-white mb-1">
                    No hay fuentes con problemas
                </h3>
                <p class="text-sm text-white/50">
                    Todos los medios estan pasando las pruebas de integridad.
                </p>
            </div>

            <!-- Table -->
            <div v-else class="overflow-x-auto">
                <table class="w-full">
                    <thead>
                        <tr class="border-b border-white/10">
                            <th class="text-left text-xs font-medium text-white/50 uppercase tracking-wider px-4 py-3">
                                Contenido / Episodio
                            </th>
                            <th class="text-left text-xs font-medium text-white/50 uppercase tracking-wider px-4 py-3">
                                Calidad
                            </th>
                            <th class="text-left text-xs font-medium text-white/50 uppercase tracking-wider px-4 py-3">
                                Formato
                            </th>
                            <th class="text-left text-xs font-medium text-white/50 uppercase tracking-wider px-4 py-3">
                                Fallos
                            </th>
                            <th class="text-left text-xs font-medium text-white/50 uppercase tracking-wider px-4 py-3">
                                Ultima Revision
                            </th>
                            <th class="text-right text-xs font-medium text-white/50 uppercase tracking-wider px-4 py-3">
                                Acciones
                            </th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-white/5">
                        <tr v-for="source in brokenSources" :key="source.id"
                            class="hover:bg-white/5 transition-colors">
                            <td class="px-4 py-4">
                                <div class="flex flex-col">
                                    <span class="text-sm font-medium text-white">
                                        {{ source.content_title ? source.content_title + ' — ' : '' }}{{ source.parent_title }}
                                    </span>
                                    <span class="text-xs text-white/50">{{ source.videoable_type }}</span>
                                </div>
                            </td>
                            <td class="px-4 py-4">
                                <span class="text-sm text-white/80">{{ source.quality }}</span>
                            </td>
                            <td class="px-4 py-4">
                                <span class="text-sm text-white/80 uppercase">{{ source.format }}</span>
                            </td>
                            <td class="px-4 py-4">
                                <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-500/20 text-red-400">
                                    {{ source.failure_count }} fallos
                                </span>
                            </td>
                            <td class="px-4 py-4">
                                <span class="text-sm text-white/60">{{ formatDate(source.last_checked_at) }}</span>
                            </td>
                            <td class="px-4 py-4 text-right">
                                <div class="flex items-center justify-end gap-2">
                                    <button
                                        @click="verifySource(source)"
                                        :disabled="source._checking"
                                        class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-green-500/10 hover:bg-green-500/20 text-green-400 text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                                    >
                                        <svg v-if="!source._checking" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none"
                                            stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
                                            <polyline points="22 4 12 14.01 9 11.01" />
                                        </svg>
                                        <svg v-else xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none"
                                            stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                                            class="animate-spin">
                                            <path d="M21.5 2v6h-6M2.5 22v-6h6M2 11.5a10 10 0 0 1 18.8-4.3M22 12.5a10 10 0 0 1-18.8 4.2" />
                                        </svg>
                                        {{ source._checking ? 'Verificando...' : 'Verificar' }}
                                    </button>
                                    <button @click="editContent(source)"
                                        class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[var(--c-primary-color)]/20 hover:bg-[var(--c-primary-color)]/30 text-[var(--c-primary-color)] text-sm font-medium transition-colors">
                                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24"
                                            fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"
                                            stroke-linejoin="round">
                                            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" />
                                            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" />
                                        </svg>
                                        Editar
                                    </button>
                                </div>
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
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
    return new Date(dateString).toLocaleDateString('es-ES', {
        day: 'numeric',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    })
}

const editContent = (source) => {
    if (source.videoable_type === 'Content') {
        router.push(`/admin/content-manager/${source.videoable_id}/edit`)
    } else if (source.videoable_type === 'Episode') {
        alert('Edita este episodio desde el administrador de temporadas del contenido correspondiente.')
    }
}

const verifySource = async (source) => {
    source._checking = true
    try {
        await ajax.post(`/admin/video_sources/${source.id}/check`)
        setTimeout(() => {
            fetchBrokenSources()
        }, 3000)
    } catch (error) {
        console.error('Error triggering integrity check:', error)
    } finally {
        source._checking = false
    }
}

onMounted(() => {
    fetchBrokenSources()
})
</script>
