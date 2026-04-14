<template>
    <div class="p-4">
        <div class="flex flex-wrap gap-2 items-center mb-4">
            <input v-model="filters.query" class="input" placeholder="Buscar por email, usuario o ID"
                @keyup.enter="fetchSubscriptions" />
            <select v-model="filters.status" class="input" @change="fetchSubscriptions">
                <option value="">Todos los estados</option>
                <option value="active">active</option>
                <option value="approved">approved</option>
                <option value="pending">pending</option>
                <option value="cancelled">cancelled</option>
            </select>
            <select v-model="filters.provider" class="input" @change="fetchSubscriptions">
                <option value="">Todos los providers</option>
                <option value="mercado_pago">mercado_pago</option>
            </select>
            <button class="px-3 py-2 rounded bg-primary text-white" @click="fetchSubscriptions">Filtrar</button>
            <button class="px-3 py-2 rounded border" @click="fetchLogs">Ver logs</button>
        </div>

        <div v-if="loading" class="py-6">Cargando suscripciones...</div>
        <div v-else>
            <table class="w-full text-sm border-collapse">
                <thead>
                    <tr>
                        <th class="text-left p-2 border-b">ID</th>
                        <th class="text-left p-2 border-b">Usuario</th>
                        <th class="text-left p-2 border-b">Provider</th>
                        <th class="text-left p-2 border-b">Estado</th>
                        <th class="text-left p-2 border-b">Renueva</th>
                        <th class="text-left p-2 border-b">Acciones</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="sub in subscriptions" :key="sub.id">
                        <td class="p-2 border-b">{{ sub.id }}</td>
                        <td class="p-2 border-b">{{ sub.user?.email || '-' }}</td>
                        <td class="p-2 border-b">{{ sub.provider || '-' }}</td>
                        <td class="p-2 border-b">{{ sub.status || '-' }}</td>
                        <td class="p-2 border-b">{{ sub.renews_at || '-' }}</td>
                        <td class="p-2 border-b space-x-2">
                            <button class="px-2 py-1 border rounded" @click="syncSubscription(sub)">Sync</button>
                            <button class="px-2 py-1 border rounded" @click="grantSubscription(sub)">Grant 30d</button>
                            <button class="px-2 py-1 border rounded text-red-600"
                                @click="cancelSubscription(sub)">Cancelar</button>
                        </td>
                    </tr>
                    <tr v-if="!subscriptions.length">
                        <td colspan="6" class="p-4 text-center">No hay suscripciones</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <div v-if="error" class="mt-3 text-red-500 text-sm">{{ error }}</div>
        <div v-if="logs.length" class="mt-6">
            <h3 class="font-semibold mb-2">Ultimos logs</h3>
            <pre
                class="text-xs bg-black/70 text-white p-3 rounded overflow-auto max-h-64">{{ JSON.stringify(logs, null, 2) }}</pre>
        </div>
    </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { ajax } from '../../lib/Ajax'

const loading = ref(false)
const error = ref('')
const subscriptions = ref([])
const logs = ref([])

const filters = ref({
    query: '',
    status: '',
    provider: ''
})

const fetchSubscriptions = async () => {
    loading.value = true
    error.value = ''

    try {
        const { data } = await ajax.get('/admin/subscriptions.json', { params: filters.value })
        subscriptions.value = data?.data || []
    } catch (e) {
        error.value = e?.response?.data?.error || 'No se pudieron cargar las suscripciones'
    } finally {
        loading.value = false
    }
}

const fetchLogs = async () => {
    try {
        const { data } = await ajax.get('/admin/subscriptions/logs.json')
        logs.value = data?.data || []
    } catch (e) {
        error.value = e?.response?.data?.error || 'No se pudieron cargar los logs'
    }
}

const syncSubscription = async (sub) => {
    try {
        await ajax.post(`/admin/subscriptions/${sub.id}/sync`)
        await fetchSubscriptions()
    } catch (e) {
        error.value = e?.response?.data?.error || 'No se pudo sincronizar'
    }
}

const grantSubscription = async (sub) => {
    try {
        await ajax.post(`/admin/subscriptions/${sub.id}/grant`, { days: 30 })
        await fetchSubscriptions()
    } catch (e) {
        error.value = e?.response?.data?.error || 'No se pudo otorgar acceso'
    }
}

const cancelSubscription = async (sub) => {
    try {
        await ajax.post(`/admin/subscriptions/${sub.id}/cancel`)
        await fetchSubscriptions()
    } catch (e) {
        error.value = e?.response?.data?.error || 'No se pudo cancelar'
    }
}

onMounted(fetchSubscriptions)
</script>
