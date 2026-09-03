<template>
    <div class="flex flex-col gap-5 p-5 max-w-[1200px] animate-[fadeIn_0.2s_ease]">
        <!-- Header -->
        <div class="flex justify-between items-start gap-4 pb-5 border-b border-white/6">
            <div class="flex-1">
                <h1 class="text-2xl font-semibold text-white flex items-center gap-3 m-0">
                    <CIcon icon="creditCard" :size="28" class="text-[var(--c-tertiary-400,#0095d9)]" />
                    Gestor de Suscripciones
                </h1>
                <p class="text-sm text-white/45 mt-2">Monitorea suscripciones, pagos y la sincronización de cobros</p>
            </div>
            <CButton variant="ghost" icon="rotateCw" :loading="loading" @click="refreshAll">
                Actualizar Todo
            </CButton>
        </div>

        <!-- Tabs -->
            <CTabs v-model="currentTab" :items="tabItems" variant="underline" />

        <!-- Error -->
        <CAlert v-if="error" type="danger" dismissible @dismiss="error = ''">
            {{ error }}
        </CAlert>

        <!-- Overview Tab -->
        <div v-if="currentTab === 'overview'" class="grid grid-cols-3 gap-3 max-[1024px]:grid-cols-2 max-[767px]:grid-cols-1">
            <CStatCard label="Total de Suscripciones" :value="realStats.total || subscriptions.length"
                icon="users" />
            <CStatCard label="Activas" :value="realStats.active || activeSubscriptionsCount"
                icon="checkCircle" color="success" />
            <CStatCard label="Pendientes" :value="realStats.pending || 0"
                icon="clock" color="warning" />
            <CStatCard label="Canceladas" :value="realStats.cancelled || 0"
                icon="x" color="danger" />
            <CStatCard label="Ingresos este mes" :value="formatRevenue(realStats.revenue_this_month)"
                icon="circleDollarSign" color="info" />
            <CStatCard label="Oferta comercial" value="1" icon="package" />
        </div>

        <!-- Subscriptions Tab -->
        <div v-if="currentTab === 'subscriptions'" class="p-5 bg-white/[0.03] border border-white/6 rounded-lg">
            <div class="flex justify-between items-start gap-4 mb-5">
                <div>
                    <h2 class="text-base font-semibold text-white/90 flex items-center gap-2.5 m-0">
                        <CIcon icon="list" :size="20" />
                        Suscripciones
                    </h2>
                    <p class="text-xs text-white/40 mt-1.5 m-0">
                        Administra suscripciones de usuarios y realiza acciones administrativas
                    </p>
                </div>
            </div>

            <!-- Create Manual Subscription -->
            <div class="mb-2">
                <button
                    class="flex items-center gap-2 px-3 py-2 rounded-md bg-white/[0.03] border border-dashed border-white/15 text-white/70 text-sm cursor-pointer w-full text-left transition-all hover:bg-white/[0.06] hover:border-white/25 hover:text-white"
                    @click="showManualForm = !showManualForm">
                    <CIcon :icon="showManualForm ? 'chevronDown' : 'chevronRight'" :size="16" />
                    <CIcon icon="users" :size="16" />
                    Crear Suscripción Manual
                </button>
                <div v-if="showManualForm"
                    class="mt-3 p-4 rounded-lg bg-[rgba(0,200,83,0.03)] border border-[rgba(0,200,83,0.12)]">
                    <div class="grid grid-cols-[1fr_160px_auto] gap-3.5 items-end max-[1024px]:grid-cols-2 max-[767px]:grid-cols-1">
                        <CFormRow label="Buscar Usuario">
                            <div class="relative">
                                <CInput v-model="manualUserQuery" placeholder="Escribe email o nombre de usuario..."
                                    @input="onUserSearchInput" />
                                <div v-if="userSearchResults.length > 0"
                                    class="absolute z-10 mt-1 w-full rounded-md border border-white/10 bg-black/60 overflow-hidden max-h-[240px] overflow-y-auto">
                                    <button v-for="u in userSearchResults" :key="u.id"
                                        class="flex flex-col gap-0.5 w-full px-3 py-2 border-none bg-transparent text-white/80 text-sm text-left cursor-pointer transition-colors hover:bg-white/[0.06]"
                                        :class="{ 'bg-white/[0.06]': manualUserId === u.id }"
                                        @click="selectUser(u)">
                                        <span class="font-semibold text-white">{{ u.username }}</span>
                                        <span class="text-xs text-white/40">{{ u.email }}</span>
                                    </button>
                                </div>
                                <div v-if="manualUserId"
                                    class="flex items-center gap-1.5 mt-1.5 px-2.5 py-1.5 rounded-md bg-[rgba(30,192,138,0.1)] text-[#1ec08a] text-sm">
                                    <CIcon icon="checkCircle" :size="16" />
                                    {{ manualUserName }} &lt;{{ manualUserEmail }}&gt;
                                    <button
                                        class="flex items-center justify-center ml-auto p-0.5 border-none rounded bg-transparent text-white/40 cursor-pointer hover:bg-white/10 hover:text-white"
                                        @click="clearSelectedUser">
                                        <CIcon icon="x" :size="14" />
                                    </button>
                                </div>
                            </div>
                        </CFormRow>
                        <CFormRow label="Duración">
                            <CSelect v-model="manualGrantDays" :options="grantDurationOptions" />
                        </CFormRow>
                        <div class="flex justify-end">
                            <CButton variant="primary" icon="sparkles" :loading="manualCreating"
                                :disabled="!manualUserId" @click="createManualSubscription">
                                {{ manualCreating ? 'Creando...' : 'Crear y Otorgar' }}
                            </CButton>
                        </div>
                    </div>
                </div>
            </div>

            <div class="flex items-center gap-4 my-6">
                <div class="flex-1 h-px bg-white/6"></div>
            </div>

            <!-- Filters -->
            <div class="grid grid-cols-4 gap-3.5 mb-6 max-[1024px]:grid-cols-2 max-[767px]:grid-cols-1">
                <CFormRow label="Buscar">
                    <CInput v-model="filters.query" placeholder="Email, nombre de usuario o ID"
                        @keyup.enter="fetchSubscriptions" />
                </CFormRow>
                <CFormRow label="Estado">
                    <CSelect v-model="filters.status" :options="statusOptions"
                        @update:model-value="fetchSubscriptions" />
                </CFormRow>
                <CFormRow label="Proveedor">
                    <CSelect v-model="filters.provider" :options="providerSelectOptions"
                        @update:model-value="fetchSubscriptions" />
                </CFormRow>
                <div class="flex items-end">
                    <CButton variant="primary" icon="search" @click="fetchSubscriptions">
                        Aplicar
                    </CButton>
                </div>
            </div>

            <!-- Subscriptions Table -->
            <CTable :columns="subscriptionColumns" :data="subscriptions" :loading="loading"
                empty-text="No se encontraron suscripciones" @sort="onSortSubscriptions">
                <template #cell-user="{ row }">
                    <div class="flex flex-col">
                        <span class="text-white/90 text-sm font-medium">{{ row.user?.username || 'Unknown' }}</span>
                        <span class="text-white/40 text-xs">{{ row.user?.email || '' }}</span>
                    </div>
                </template>
                <template #cell-status="{ row }">
                    <CBadge :variant="statusBadgeVariant(row.status)" dot pill size="sm">
                        {{ row.status || 'unknown' }}
                    </CBadge>
                </template>
                <template #cell-provider="{ row }">
                    <CBadge :variant="providerBadgeVariant(row.provider)" size="sm">
                        {{ formatProvider(row.provider) }}
                    </CBadge>
                </template>
                <template #cell-renews_at="{ row }">
                    <span class="text-white/40 text-xs">{{ row.renews_at ? formatDate(row.renews_at) : '-' }}</span>
                </template>
                <template #cell-actions="{ row }">
                    <div class="flex items-center gap-1">
                        <CTooltip text="Sincronizar" placement="top">
                            <button
                                class="inline-flex items-center justify-center w-7 h-7 rounded-md bg-white/5 border border-white/8 text-white/65 cursor-pointer transition-all hover:bg-white/[0.08] hover:text-white"
                                @click="syncSubscription(row)">
                                <CIcon icon="rotateCw" :size="13" />
                            </button>
                        </CTooltip>
                        <CTooltip text="Otorgar 30 días" placement="top">
                            <button
                                class="inline-flex items-center justify-center w-7 h-7 rounded-md bg-white/5 border border-white/8 text-white/65 cursor-pointer transition-all hover:bg-white/[0.08] hover:text-white"
                                @click="grantSubscription(row, 30)">
                                <CIcon icon="sparkles" :size="13" />
                            </button>
                        </CTooltip>
                        <CTooltip text="Cancelar" placement="top">
                            <button
                                class="inline-flex items-center justify-center w-7 h-7 rounded-md bg-white/5 border border-white/8 text-white/65 cursor-pointer transition-all hover:bg-red-500/10 hover:text-red-400 disabled:opacity-40 disabled:cursor-not-allowed"
                                :disabled="row.cancelled"
                                @click="cancelSubscription(row)">
                                <CIcon icon="x" :size="13" />
                            </button>
                        </CTooltip>
                    </div>
                </template>
            </CTable>
        </div>

        <!-- Logs Tab -->
        <div v-if="currentTab === 'logs'" class="p-5 bg-white/[0.03] border border-white/6 rounded-lg">
            <div class="flex justify-between items-start gap-4 mb-5">
                <div>
                    <h2 class="text-base font-semibold text-white/90 flex items-center gap-2.5 m-0">
                        <CIcon icon="code2" :size="20" />
                        Registros de Webhooks
                    </h2>
                    <p class="text-xs text-white/40 mt-1.5 m-0">
                        Monitorea los eventos entrantes de los proveedores de pago
                    </p>
                </div>
                <CButton variant="ghost" icon="rotateCw" :loading="loadingLogs" @click="fetchLogs">
                    Actualizar
                </CButton>
            </div>

            <CTable :columns="logColumns" :data="logs" :loading="loadingLogs"
                empty-text="No se encontraron registros de webhooks">
                <template #cell-provider="{ row }">
                    <CBadge :variant="providerBadgeVariant(row.provider)" pill size="sm">
                        {{ formatProvider(row.provider) }}
                    </CBadge>
                </template>
                <template #cell-status="{ row }">
                    <CBadge :variant="row.status === 200 ? 'success' : 'danger'" size="sm">
                        {{ row.status }}
                    </CBadge>
                </template>
                <template #cell-created_at="{ row }">
                    <span class="text-white/40 text-xs">{{ formatDateTime(row.created_at) }}</span>
                </template>
                <template #cell-payload="{ row }">
                    <details class="group">
                        <summary
                            class="text-xs text-white/50 cursor-pointer p-1 outline-none hover:text-white/70">
                            Payload
                        </summary>
                        <pre
                            class="mt-2 p-3 bg-black/40 rounded-md font-mono text-xs text-white/70 overflow-x-auto">{{ formatJson(row.payload) }}</pre>
                    </details>
                </template>
            </CTable>
        </div>
    </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { ajax } from '../../lib/Ajax'
import CIcon from '@/components/c-icon.vue'
import CButton from '@/components/forms/c-button'
import CInput from '@/components/forms/c-input.vue'
import CSelect from '@/components/forms/c-select.vue'
import CFormRow from '@/components/forms/CFormRow'
import CTabs from '@/components/CTabs'
import CTable from '@/components/CTable'
import CStatCard from '@/components/CStatCard'
import CBadge from '@/components/CBadge'
import CAlert from '@/components/CAlert'
import CTooltip from '@/components/CTooltip'

const currentTab = ref('overview')
const loading = ref(false)
const loadingLogs = ref(false)
const error = ref('')

const tabItems = [
    { key: 'overview', label: 'Resumen', icon: 'chartPie' },
    { key: 'subscriptions', label: 'Suscripciones', icon: 'users' },
    { key: 'logs', label: 'Registros', icon: 'code2' }
]

// Manual subscription creation
const showManualForm = ref(false)
const manualUserQuery = ref('')
const userSearchResults = ref([])
const manualUserId = ref(null)
const manualUserName = ref('')
const manualUserEmail = ref('')
const manualGrantDays = ref(30)
const manualCreating = ref(false)
let userSearchTimeout = null

const grantDurationOptions = [
    { label: '1 Día', value: 1 },
    { label: '7 Días', value: 7 },
    { label: '15 Días', value: 15 },
    { label: '30 Días', value: 30 },
    { label: '90 Días', value: 90 },
    { label: '1 Año', value: 365 }
]

const statusOptions = [
    { label: 'Todos', value: '' },
    { label: 'Activas', value: 'active' },
    { label: 'Aprobadas', value: 'approved' },
    { label: 'Pendientes', value: 'pending' },
    { label: 'Canceladas', value: 'cancelled' }
]

const subscriptions = ref([])
const logs = ref([])
const realStats = ref({})
const availableProviders = ref([])

const filters = ref({ query: '', status: '', provider: '' })

const activeSubscriptionsCount = computed(() =>
    subscriptions.value.filter((sub) => ['active', 'approved'].includes((sub.status || '').toLowerCase())).length
)

const providerOptions = computed(() =>
    availableProviders.value.length > 0 ? availableProviders.value : [{ key: 'mercado_pago', label: 'Mercado Pago' }]
)

const providerSelectOptions = computed(() => [
    { label: 'Todos', value: '' },
    ...providerOptions.value.map(p => ({ label: p.label, value: p.key }))
])

const subscriptionColumns = [
    { key: 'id', label: 'ID', sortable: true, width: '80px' },
    { key: 'user', label: 'Usuario', sortable: true },
    { key: 'status', label: 'Estado', sortable: true },
    { key: 'provider', label: 'Proveedor', sortable: true },
    { key: 'renews_at', label: 'Renueva', sortable: true },
    { key: 'actions', label: '', width: '120px', align: 'right' }
]

const logColumns = [
    { key: 'provider', label: 'Proveedor' },
    { key: 'event_type', label: 'Evento', sortable: true },
    { key: 'status', label: 'Status', sortable: true, width: '80px' },
    { key: 'created_at', label: 'Fecha', sortable: true },
    { key: 'payload', label: 'Payload', width: '100px' }
]

const refreshStats = async () => {
    try {
        const { data } = await ajax.get('/admin/subscriptions/stats.json')
        realStats.value = data || {}
    } catch {
        // silent fail for stats
    }
}

const refreshAll = async () => {
    loading.value = true
    await Promise.all([fetchSubscriptions(), refreshStats()])
    loading.value = false
}

const fetchSubscriptions = async () => {
    error.value = ''
    try {
        const { data } = await ajax.get('/admin/subscriptions.json', { params: filters.value })
        subscriptions.value = (data?.data || []).map(s => ({ ...s, _grantDays: 30 }))
        availableProviders.value = data?.meta?.available_providers || availableProviders.value
    } catch (e) {
        error.value = e?.response?.data?.error || 'Failed to load subscriptions'
    }
}

const fetchLogs = async () => {
    loadingLogs.value = true
    try {
        const { data } = await ajax.get('/admin/subscriptions/logs.json')
        logs.value = data?.data || []
    } catch (e) {
        error.value = e?.response?.data?.error || 'Failed to load logs'
    } finally {
        loadingLogs.value = false
    }
}

const syncSubscription = async (sub) => {
    try {
        await ajax.post(`/admin/subscriptions/${sub.id}/sync`)
        await fetchSubscriptions()
    } catch (e) {
        error.value = e?.response?.data?.error || 'Failed to sync'
    }
}

const grantSubscription = async (sub, days) => {
    try {
        await ajax.post(`/admin/subscriptions/${sub.id}/grant`, { days })
        await fetchSubscriptions()
        await refreshStats()
    } catch (e) {
        error.value = e?.response?.data?.error || 'Failed to grant access'
    }
}

const cancelSubscription = async (sub) => {
    if (!confirm('Are you sure you want to cancel this subscription?')) return
    try {
        await ajax.post(`/admin/subscriptions/${sub.id}/cancel`)
        await fetchSubscriptions()
        await refreshStats()
    } catch (e) {
        error.value = e?.response?.data?.error || 'Failed to cancel'
    }
}

const onSortSubscriptions = (key) => {
    // Sort locally
    const dir = subscriptions.value._sortDir === 'asc' ? 'desc' : 'asc'
    subscriptions.value._sortDir = dir
    subscriptions.value.sort((a, b) => {
        let va = a[key] ?? ''
        let vb = b[key] ?? ''
        if (typeof va === 'string') va = va.toLowerCase()
        if (typeof vb === 'string') vb = vb.toLowerCase()
        if (va < vb) return dir === 'asc' ? -1 : 1
        if (va > vb) return dir === 'asc' ? 1 : -1
        return 0
    })
}

const statusBadgeVariant = (status) => {
    const v = (status || '').toLowerCase()
    if (['active', 'approved'].includes(v)) return 'success'
    if (['pending', 'in_process'].includes(v)) return 'warning'
    if (['cancelled', 'canceled', 'rejected'].includes(v)) return 'danger'
    return 'muted'
}

const providerBadgeVariant = (provider) => {
    const v = (provider || '').toLowerCase()
    if (v === 'mercado_pago') return 'info'
    if (v === 'lemon_squeezy') return 'primary'
    if (v === 'google_play') return 'success'
    return 'muted'
}

const formatDate = (v) => {
    if (!v) return '-'
    const d = new Date(v)
    return isNaN(d.getTime()) ? '-' : d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })
}

const formatDateTime = (v) => {
    if (!v) return '-'
    const d = new Date(v)
    return isNaN(d.getTime()) ? '-' : d.toLocaleString('en-US')
}

const formatJson = (payload) => {
    if (typeof payload === 'string') {
        try { payload = JSON.parse(payload) } catch { return payload }
    }
    return JSON.stringify(payload, null, 2)
}

const formatProvider = (provider) => {
    if (!provider) return 'N/A'
    const opt = providerOptions.value.find((c) => c.key === String(provider))
    if (opt) return opt.label
    return String(provider).split('_').map((t) => t.charAt(0).toUpperCase() + t.slice(1)).join(' ')
}

const formatRevenue = (amount) => {
    if (!amount && amount !== 0) return '-'
    const currency = realStats.value?.currency || 'UYU'
    return new Intl.NumberFormat('es-UY', { style: 'currency', currency }).format(amount)
}

const onUserSearchInput = () => {
    clearTimeout(userSearchTimeout)
    const q = manualUserQuery.value.trim()
    if (q.length < 2) {
        userSearchResults.value = []
        return
    }
    userSearchTimeout = setTimeout(async () => {
        try {
            const { data } = await ajax.get('/admin/users.json', { params: { query: q } })
            userSearchResults.value = (data?.data || []).slice(0, 10)
        } catch {
            userSearchResults.value = []
        }
    }, 300)
}

const selectUser = (u) => {
    manualUserId.value = u.id
    manualUserName.value = u.username
    manualUserEmail.value = u.email
    manualUserQuery.value = ''
    userSearchResults.value = []
}

const clearSelectedUser = () => {
    manualUserId.value = null
    manualUserName.value = ''
    manualUserEmail.value = ''
}

const createManualSubscription = async () => {
    if (!manualUserId.value) return
    manualCreating.value = true
    error.value = ''
    try {
        await ajax.post('/admin/subscriptions/create_grant', {
            user_id: manualUserId.value,
            days: manualGrantDays.value
        })
        clearSelectedUser()
        showManualForm.value = false
        await fetchSubscriptions()
        await refreshStats()
    } catch (e) {
        error.value = e?.response?.data?.error || 'Failed to create subscription'
    } finally {
        manualCreating.value = false
    }
}

onMounted(() => {
    refreshAll()
})
</script>

<style scoped>
@keyframes fadeIn {
    from { opacity: 0; transform: translateY(8px); }
    to { opacity: 1; transform: translateY(0); }
}
</style>
