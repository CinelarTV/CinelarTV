<template>
    <div class="subscriptions-admin">
        <!-- Header -->
        <div class="subscriptions-admin__header">
            <div class="subscriptions-admin__header-content">
                <h1 class="subscriptions-admin__title">
                    <CIcon icon="credit-card" :size="28" class="subscriptions-admin__icon" />
                    Gestor de Suscripciones
                </h1>
                <p class="subscriptions-admin__description">
                    Administra planes, monitorea suscripciones y realiza acciones administrativas
                </p>
            </div>
            <div class="subscriptions-admin__actions">
                <button class="subscriptions-admin__btn" @click="refreshAll" :disabled="loading">
                    <CIcon icon="refresh-cw" :size="16" :class="{ 'subscriptions-admin__btn--spinning': loading }" />
                    Actualizar Todo
                </button>
            </div>
        </div>

        <!-- Tabs -->
        <div class="subscriptions-admin__tabs">
            <button class="subscriptions-admin__tab"
                :class="{ 'subscriptions-admin__tab--active': currentTab === 'overview' }"
                @click="currentTab = 'overview'">
                <CIcon icon="pie-chart" :size="16" /> Resumen
            </button>
            <button class="subscriptions-admin__tab"
                :class="{ 'subscriptions-admin__tab--active': currentTab === 'subscriptions' }"
                @click="currentTab = 'subscriptions'">
                <CIcon icon="users" :size="16" /> Suscripciones
            </button>
            <button class="subscriptions-admin__tab"
                :class="{ 'subscriptions-admin__tab--active': currentTab === 'plans' }" @click="currentTab = 'plans'">
                <CIcon icon="package" :size="16" /> Planes
            </button>
            <button class="subscriptions-admin__tab"
                :class="{ 'subscriptions-admin__tab--active': currentTab === 'logs' }"
                @click="currentTab = 'logs'; fetchLogs()">
                <CIcon icon="terminal" :size="16" /> Registros
            </button>
        </div>

        <div v-if="error" class="subscriptions-admin__error">
            <CIcon icon="alert-circle" :size="18" />
            {{ error }}
            <button class="subscriptions-admin__error-close" @click="error = ''">
                <CIcon icon="x" :size="16" />
            </button>
        </div>

        <!-- Overview Tab -->
        <div v-show="currentTab === 'overview'" class="subscriptions-admin__overview">
            <div class="subscriptions-admin__stats">
                <div class="subscriptions-admin__stat-card">
                    <div class="subscriptions-admin__stat-icon">
                        <CIcon icon="users" :size="24" />
                    </div>
                    <div class="subscriptions-admin__stat-content">
                        <span class="subscriptions-admin__stat-label">Total de Suscripciones</span>
                        <strong class="subscriptions-admin__stat-value">{{ realStats.total || subscriptions.length
                            }}</strong>
                    </div>
                </div>
                <div class="subscriptions-admin__stat-card">
                    <div class="subscriptions-admin__stat-icon subscriptions-admin__stat-icon--active">
                        <CIcon icon="check-circle" :size="24" />
                    </div>
                    <div class="subscriptions-admin__stat-content">
                        <span class="subscriptions-admin__stat-label">Activas</span>
                        <strong class="subscriptions-admin__stat-value">{{ realStats.active || activeSubscriptionsCount
                            }}</strong>
                    </div>
                </div>
                <div class="subscriptions-admin__stat-card">
                    <div class="subscriptions-admin__stat-icon subscriptions-admin__stat-icon--pending">
                        <CIcon icon="clock" :size="24" />
                    </div>
                    <div class="subscriptions-admin__stat-content">
                        <span class="subscriptions-admin__stat-label">Pendientes</span>
                        <strong class="subscriptions-admin__stat-value">{{ realStats.pending || 0 }}</strong>
                    </div>
                </div>
                <div class="subscriptions-admin__stat-card">
                    <div class="subscriptions-admin__stat-icon subscriptions-admin__stat-icon--cancelled">
                        <CIcon icon="x-circle" :size="24" />
                    </div>
                    <div class="subscriptions-admin__stat-content">
                        <span class="subscriptions-admin__stat-label">Canceladas</span>
                        <strong class="subscriptions-admin__stat-value">{{ realStats.cancelled || 0 }}</strong>
                    </div>
                </div>
                <div class="subscriptions-admin__stat-card">
                    <div class="subscriptions-admin__stat-icon subscriptions-admin__stat-icon--primary">
                        <CIcon icon="dollar-sign" :size="24" />
                    </div>
                    <div class="subscriptions-admin__stat-content">
                        <span class="subscriptions-admin__stat-label">Ingresos este mes</span>
                        <strong class="subscriptions-admin__stat-value">{{ formatRevenue(realStats.revenue_this_month)
                            }}</strong>
                    </div>
                </div>
                <div class="subscriptions-admin__stat-card">
                    <div class="subscriptions-admin__stat-icon">
                        <CIcon icon="package" :size="24" />
                    </div>
                    <div class="subscriptions-admin__stat-content">
                        <span class="subscriptions-admin__stat-label">Planes Disponibles</span>
                        <strong class="subscriptions-admin__stat-value">{{ plans.length }}</strong>
                    </div>
                </div>
            </div>
        </div>

        <!-- Subscriptions Tab -->
        <div v-show="currentTab === 'subscriptions'" class="subscriptions-admin__card">
            <div class="subscriptions-admin__card-header">
                <div>
                    <h2 class="subscriptions-admin__card-title">
                        <CIcon icon="list" :size="20" />
                        Suscripciones
                    </h2>
                    <p class="subscriptions-admin__card-description">
                        Administra suscripciones de usuarios y realiza acciones administrativas
                    </p>
                </div>
            </div>

            <!-- Create Manual Subscription -->
            <div class="subscriptions-admin__manual-section">
                <button class="subscriptions-admin__manual-toggle" @click="showManualForm = !showManualForm">
                    <CIcon :icon="showManualForm ? 'chevron-down' : 'chevron-right'" :size="16" />
                    <CIcon icon="user-plus" :size="16" />
                    Crear Suscripción Manual
                </button>
                <div v-if="showManualForm" class="subscriptions-admin__manual-form">
                    <div class="subscriptions-admin__filters">
                        <div class="subscriptions-admin__field">
                            <label class="subscriptions-admin__label">Buscar Usuario</label>
                            <input v-model="manualUserQuery" class="subscriptions-admin__input"
                                placeholder="Escribe email o nombre de usuario..." @input="onUserSearchInput" />
                            <div v-if="userSearchResults.length > 0" class="subscriptions-admin__user-results">
                                <button v-for="u in userSearchResults" :key="u.id"
                                    class="subscriptions-admin__user-result"
                                    :class="{ 'subscriptions-admin__user-result--selected': manualUserId === u.id }"
                                    @click="selectUser(u)">
                                    <span class="subscriptions-admin__user-result-name">{{ u.username }}</span>
                                    <span class="subscriptions-admin__user-result-email">{{ u.email }}</span>
                                </button>
                            </div>
                            <div v-if="manualUserId" class="subscriptions-admin__user-selected">
                                <CIcon icon="check-circle" :size="16" />
                                {{ manualUserName }} &lt;{{ manualUserEmail }}&gt;
                                <button class="subscriptions-admin__user-clear" @click="clearSelectedUser">
                                    <CIcon icon="x" :size="14" />
                                </button>
                            </div>
                        </div>
                        <div class="subscriptions-admin__field">
                            <label class="subscriptions-admin__label">Duración</label>
                            <select v-model="manualGrantDays" class="subscriptions-admin__select">
                                <option :value="1">1 Día</option>
                                <option :value="7">7 Días</option>
                                <option :value="15">15 Días</option>
                                <option :value="30">30 Días</option>
                                <option :value="90">90 Días</option>
                                <option :value="365">1 Año</option>
                            </select>
                        </div>
                        <div class="subscriptions-admin__field subscriptions-admin__field--actions">
                            <button class="subscriptions-admin__btn subscriptions-admin__btn--primary"
                                @click="createManualSubscription" :disabled="!manualUserId || manualCreating">
                                <CIcon icon="gift" :size="16" :class="{ 'subscriptions-admin__btn--spinning': manualCreating }" />
                                {{ manualCreating ? 'Creando...' : 'Crear y Otorgar' }}
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <div class="subscriptions-admin__divider"></div>

            <!-- Filters -->
            <div class="subscriptions-admin__filters">
                <div class="subscriptions-admin__field">
                    <label class="subscriptions-admin__label">Buscar</label>
                    <input v-model="filters.query" class="subscriptions-admin__input"
                        placeholder="Email, nombre de usuario o ID" @keyup.enter="fetchSubscriptions" />
                </div>
                <div class="subscriptions-admin__field">
                    <label class="subscriptions-admin__label">Estado</label>
                    <select v-model="filters.status" class="subscriptions-admin__select" @change="fetchSubscriptions">
                        <option value="">Todos</option>
                        <option value="active">Activas</option>
                        <option value="approved">Aprobadas</option>
                        <option value="pending">Pendientes</option>
                        <option value="cancelled">Canceladas</option>
                    </select>
                </div>
                <div class="subscriptions-admin__field">
                    <label class="subscriptions-admin__label">Proveedor</label>
                    <select v-model="filters.provider" class="subscriptions-admin__select" @change="fetchSubscriptions">
                        <option value="">Todos</option>
                        <option v-for="provider in providerOptions" :key="provider.key" :value="provider.key">
                            {{ provider.label }}
                        </option>
                    </select>
                </div>
                <div class="subscriptions-admin__field subscriptions-admin__field--actions">
                    <button class="subscriptions-admin__btn subscriptions-admin__btn--primary"
                        @click="fetchSubscriptions">
                        <CIcon icon="search" :size="16" />
                        Aplicar
                    </button>
                </div>
            </div>

            <div class="subscriptions-admin__divider"></div>

            <div v-if="loading" class="subscriptions-admin__loading">
                <CIcon icon="loader" :size="32" class="subscriptions-admin__loading-icon" />
                <p>Cargando suscripciones...</p>
            </div>

            <div v-else-if="!subscriptions.length" class="subscriptions-admin__empty">
                <CIcon icon="inbox" :size="48" class="subscriptions-admin__empty-icon" />
                <p class="subscriptions-admin__empty-title">No se encontraron suscripciones</p>
                <p class="subscriptions-admin__empty-description">
                    No hay suscripciones que coincidan con los filtros actuales
                </p>
            </div>

            <div v-else class="subscriptions-admin__list">
                <div v-for="sub in subscriptions" :key="sub.id" class="subscription__card">
                    <div class="subscription__header">
                        <div class="subscription__info">
                            <span class="subscription__id">#{{ sub.id }}</span>
                            <span class="subscription__user">{{ sub.user?.email || sub.user?.username || 'Unknown'
                                }}</span>
                            <span class="subscription__date" v-if="sub.renews_at">
                                <CIcon icon="calendar" :size="14" />
                                Renews: {{ formatDate(sub.renews_at) }}
                            </span>
                        </div>
                        <span class="subscription__badge" :class="statusBadgeClass(sub.status)">
                            {{ sub.status || 'unknown' }}
                        </span>
                    </div>
                    <div class="subscription__meta">
                        <div class="subscription__meta-item">
                            <CIcon icon="credit-card" :size="14" />
                            <span>{{ formatProvider(sub.provider) }}</span>
                        </div>
                        <div class="subscription__meta-item" v-if="sub.product_name">
                            <CIcon icon="package" :size="14" />
                            <span>{{ sub.product_name }}</span>
                        </div>
                    </div>
                    <div class="subscription__actions">
                        <button class="subscription__btn" @click="syncSubscription(sub)">
                            <CIcon icon="refresh-cw" :size="14" />
                            Sincronizar
                        </button>

                        <!-- Grant Access Group -->
                        <div class="subscription__grant-group">
                            <select v-model="sub._grantDays" class="subscription__grant-select">
                                <option :value="1">1 Día</option>
                                <option :value="7">7 Días</option>
                                <option :value="15">15 Días</option>
                                <option :value="30">30 Días</option>
                                <option :value="90">90 Días</option>
                                <option :value="365">1 Año</option>
                            </select>
                            <button class="subscription__btn" @click="grantSubscription(sub)">
                                <CIcon icon="gift" :size="14" />
                                Otorgar
                            </button>
                        </div>

                        <button class="subscription__btn subscription__btn--danger" @click="cancelSubscription(sub)"
                            :disabled="sub.cancelled">
                            <CIcon icon="x-circle" :size="14" />
                            Cancelar
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- Plans Tab -->
        <div v-show="currentTab === 'plans'" class="subscriptions-admin__card">
            <div class="subscriptions-admin__card-header">
                <div>
                    <h2 class="subscriptions-admin__card-title">
                        <CIcon icon="package" :size="20" />
                        Planes
                    </h2>
                    <p class="subscriptions-admin__card-description">
                        Administra planes para {{ currentProviderLabel }}
                    </p>
                </div>
                <div class="subscriptions-admin__provider-controls">
                    <div class="subscriptions-admin__field">
                        <label class="subscriptions-admin__label">Proveedor</label>
                        <select v-model="selectedProviderKey" class="subscriptions-admin__select"
                            @change="onProviderChange">
                            <option v-for="provider in providerOptions" :key="provider.key" :value="provider.key">
                                {{ provider.label }}
                            </option>
                        </select>
                    </div>
                    <label class="subscriptions-admin__toggle" v-if="supportsPlanManagement">
                        <input type="checkbox" v-model="showAllPlans" @change="fetchPlans" />
                        <span class="subscriptions-admin__toggle-label">
                            <CIcon :icon="showAllPlans ? 'check-square' : 'square'" :size="18" />
                            Mostrar todos los planes del comercio
                        </span>
                    </label>
                </div>
            </div>

            <div v-if="!plans.length && !isMobileAppProvider" class="subscriptions-admin__empty">
                <CIcon icon="package-x" :size="48" class="subscriptions-admin__empty-icon" />
                <p class="subscriptions-admin__empty-title">No hay planes disponibles</p>
                <p class="subscriptions-admin__empty-description">
                    Crea un plan desde {{ currentProviderLabel }} o usa el formulario a continuación
                </p>
            </div>
            <div v-if="!plans.length && isMobileAppProvider" class="subscriptions-admin__empty">
                <CIcon icon="package-x" :size="48" class="subscriptions-admin__empty-icon" />
                <p class="subscriptions-admin__empty-title">No hay producto de Google Play configurado</p>
                <p class="subscriptions-admin__empty-description">
                    Configura el producto de suscripción de Google Play en la configuración del sitio
                </p>
            </div>
            <div v-else class="subscriptions-admin__plans">
                <div class="subscriptions-admin__info-box subscriptions-admin__info-box--plan">
                    <CIcon icon="info" :size="18" class="subscriptions-admin__info-icon" />
                    <div class="subscriptions-admin__info-content">
                        <p>El plan seleccionado es el que verán los usuarios en su página de facturación. Los usuarios de cada región verán el plan del proveedor que les corresponde.</p>
                    </div>
                </div>
                <div v-for="plan in plans" :key="plan.id || plan.product_id" class="plan__card"
                    :class="{ 'plan__card--active': (plan.id || plan.product_id) === String(activePlanId) }">
                    <div class="plan__content">
                        <div class="plan__header">
                            <h3 class="plan__name">{{ plan.reason || plan.product_id || plan.name }}</h3>
                            <span v-if="(plan.id || plan.product_id) === String(activePlanId)" class="plan__badge">
                                <CIcon icon="check" :size="14" /> Activo
                            </span>
                        </div>
                        <div class="plan__details">
                            <div class="plan__detail" v-if="plan.auto_recurring?.transaction_amount">
                                <CIcon icon="dollar-sign" :size="14" />
                                <span>{{ plan.auto_recurring?.transaction_amount }} {{ plan.auto_recurring?.currency_id
                                    }}</span>
                            </div>
                            <div class="plan__detail" v-if="plan.auto_recurring?.frequency">
                                <CIcon icon="calendar" :size="14" />
                                <span>{{ plan.auto_recurring?.frequency }} {{ plan.auto_recurring?.frequency_type
                                    }}</span>
                            </div>
                            <div class="plan__detail" v-if="plan.price">
                                <CIcon icon="dollar-sign" :size="14" />
                                <span>{{ plan.price }} {{ plan.currency || 'USD' }}</span>
                            </div>
                            <div class="plan__detail" v-if="plan.billing_period">
                                <CIcon icon="calendar" :size="14" />
                                <span>{{ plan.billing_period }}</span>
                            </div>
                            <div class="plan__detail">
                                <CIcon icon="hash" :size="14" />
                                <span class="plan__id">ID: {{ plan.id || plan.product_id }}</span>
                            </div>
                        </div>
                    </div>
                    <div class="plan__actions">
                        <button class="plan__btn"
                            :class="{ 'plan__btn--active': (plan.id || plan.product_id) === String(activePlanId) }"
                            @click="selectPlan(plan)" :disabled="(plan.id || plan.product_id) === String(activePlanId)">
                            <CIcon
                                :icon="(plan.id || plan.product_id) === String(activePlanId) ? 'check-circle' : 'arrow-right'"
                                :size="16" />
                            {{ (plan.id || plan.product_id) === String(activePlanId) ? 'Plan de usuario activo' : 'Usar este plan' }}
                        </button>
                    </div>
                </div>
            </div>

            <div class="subscriptions-admin__divider" v-if="supportsPlanManagement">
                <span class="subscriptions-admin__divider-text">O crea un nuevo plan</span>
            </div>

            <form class="subscriptions-admin__form" @submit.prevent="createPlan" v-if="supportsPlanManagement">
                <div class="subscriptions-admin__form-grid">
                    <div class="subscriptions-admin__field">
                        <label class="subscriptions-admin__label">Nombre del Plan</label>
                        <input v-model="planForm.reason" class="subscriptions-admin__input"
                            placeholder="ej., Plan Mensual" required />
                    </div>
                    <div class="subscriptions-admin__field">
                        <label class="subscriptions-admin__label">Monto</label>
                        <input v-model.number="planForm.amount" type="number" step="0.01" min="0"
                            class="subscriptions-admin__input" required />
                    </div>
                    <div class="subscriptions-admin__field">
                        <label class="subscriptions-admin__label">Moneda</label>
                        <select v-model="planForm.currency_id" class="subscriptions-admin__select">
                            <option value="UYU">UYU - Peso Uruguayo</option>
                            <option value="USD">USD - Dólar Americano</option>
                            <option value="ARS">ARS - Peso Argentino</option>
                            <option value="BRL">BRL - Real Brasileño</option>
                        </select>
                    </div>
                    <div class="subscriptions-admin__field">
                        <label class="subscriptions-admin__label">Frecuencia de Facturación</label>
                        <select v-model.number="planForm.frequency" class="subscriptions-admin__select">
                            <option :value="1">Mensual</option>
                            <option :value="3">Trimestral</option>
                            <option :value="6">Semestral</option>
                            <option :value="12">Anual</option>
                        </select>
                    </div>
                </div>
                <div class="subscriptions-admin__form-actions">
                    <button class="subscriptions-admin__btn subscriptions-admin__btn--primary" type="submit">
                        <CIcon icon="plus" :size="16" />
                        Crear Plan
                    </button>
                </div>
            </form>

            <div v-if="!supportsPlanManagement" class="subscriptions-admin__info-box">
                <CIcon icon="info" :size="20" class="subscriptions-admin__info-icon" />
                <div class="subscriptions-admin__info-content">
                    <h4>Configuración del Proveedor</h4>
                    <p>{{ currentProviderLabel }} no soporta gestión de planes en línea. Los planes deben configurarse
                        directamente en la consola de {{ currentProviderLabel }}.</p>
                </div>
            </div>
        </div>

        <!-- Logs Tab -->
        <div v-show="currentTab === 'logs'" class="subscriptions-admin__card">
            <div class="subscriptions-admin__card-header">
                <div>
                    <h2 class="subscriptions-admin__card-title">
                        <CIcon icon="terminal" :size="20" />
                        Registros de Webhooks
                    </h2>
                    <p class="subscriptions-admin__card-description">
                        Monitorea los eventos entrantes de los proveedores de pago
                    </p>
                </div>
                <button class="subscriptions-admin__btn" @click="fetchLogs" :disabled="loadingLogs">
                    <CIcon icon="refresh-cw" :size="16"
                        :class="{ 'subscriptions-admin__btn--spinning': loadingLogs }" /> Actualizar
                </button>
            </div>

            <div v-if="loadingLogs" class="subscriptions-admin__loading">
                <CIcon icon="loader" :size="32" class="subscriptions-admin__loading-icon" />
                <p>Cargando registros...</p>
            </div>
            <div v-else-if="!logs.length" class="subscriptions-admin__empty">
                <CIcon icon="inbox" :size="48" class="subscriptions-admin__empty-icon" />
                <p class="subscriptions-admin__empty-title">No se encontraron registros de webhooks</p>
                <p class="subscriptions-admin__empty-description">Los eventos aparecerán aquí cuando lleguen los webhooks</p>
            </div>
            <div v-else class="subscriptions-admin__logs">
                <div v-for="log in logs" :key="log.id" class="log__item">
                    <div class="log__header">
                        <span class="log__provider" :class="`log__provider--${log.provider}`">{{
                            formatProvider(log.provider) }}</span>
                        <span class="log__event">{{ log.event_type }}</span>
                        <span class="log__date">{{ formatDateTime(log.created_at) }}</span>
                    </div>
                    <div class="log__body">
                        <span class="log__status" :class="log.status === 200 ? 'status-ok' : 'status-err'">Status: {{
                            log.status }}</span>
                        <details class="log__details">
                            <summary>Payload</summary>
                            <pre class="log__pre">{{ formatJson(log.payload) }}</pre>
                        </details>
                    </div>
                </div>
            </div>
        </div>

    </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { ajax } from '../../lib/Ajax'
import CIcon from '@/components/c-icon.vue'

const currentTab = ref('overview') // 'overview', 'subscriptions', 'plans', 'logs'
const loading = ref(false)
const loadingLogs = ref(false)
const error = ref('')

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

const subscriptions = ref([])
const plans = ref([])
const logs = ref([])
const realStats = ref({})

const showAllPlans = ref(false)
const activePlanId = ref('')
const currentProviderKey = ref('')
const selectedProviderKey = ref('')
const availableProviders = ref([])

const filters = ref({ query: '', status: '', provider: '' })

const planForm = ref({
    reason: 'Monthly Subscription Plan',
    amount: 390,
    currency_id: 'UYU',
    frequency: 1,
    frequency_type: 'months'
})

const activeSubscriptionsCount = computed(() =>
    subscriptions.value.filter((sub) => ['active', 'approved'].includes((sub.status || '').toLowerCase())).length
)

const providerOptions = computed(() => availableProviders.value.length > 0 ? availableProviders.value : [{ key: 'mercado_pago', label: 'Mercado Pago' }])

const currentProviderLabel = computed(() => {
    const provider = providerOptions.value.find((o) => o.key === selectedProviderKey.value)
    return provider ? provider.label : selectedProviderKey.value ? selectedProviderKey.value.replace(/_/g, ' ') : 'Current'
})

const isMobileAppProvider = computed(() => selectedProviderKey.value === 'google_play')

const supportsPlanManagement = computed(() => !isMobileAppProvider.value)

const activePlanName = computed(() => {
    if (!activePlanId.value) return 'No plan selected'
    const match = plans.value.find((p) => String(p.id) === String(activePlanId.value))
    return match?.reason || `Plan ${activePlanId.value}`
})

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
    await Promise.all([fetchSubscriptions(), fetchPlans(), refreshStats()])
    loading.value = false
}

const fetchSubscriptions = async () => {
    error.value = ''
    try {
        const { data } = await ajax.get('/admin/subscriptions.json', { params: filters.value })
        // Attach default grantDays to each for the UI dropdown
        subscriptions.value = (data?.data || []).map(s => ({ ...s, _grantDays: 30 }))
        availableProviders.value = data?.meta?.available_providers || availableProviders.value
        currentProviderKey.value = data?.meta?.current_provider || currentProviderKey.value
        // Initialize selected provider if not set
        if (!selectedProviderKey.value && availableProviders.value.length > 0) {
            selectedProviderKey.value = currentProviderKey.value || availableProviders.value[0].key
        }
    } catch (e) {
        error.value = e?.response?.data?.error || 'Failed to load subscriptions'
    }
}

const fetchPlans = async () => {
    try {
        if (isMobileAppProvider.value) {
            await loadGooglePlayProduct()
        } else {
            const { data } = await ajax.get('/admin/subscriptions/plans.json', {
                params: {
                    managed_only: !showAllPlans.value,
                    provider: selectedProviderKey.value
                }
            })
            plans.value = data?.data || []
            activePlanId.value = data?.meta?.active_plan_id || ''
        }
    } catch (e) {
        error.value = e?.response?.data?.error || 'Failed to load plans'
    }
}

const loadGooglePlayProduct = async () => {
    try {
        const { data } = await ajax.get('/admin/site_settings.json')
        const productId = data?.google_play_subscription_product_id || ''
        plans.value = productId ? [{
            product_id: productId,
            name: 'Google Play',
            reason: 'Google Play',
            id: productId
        }] : []

        const { data: plansData } = await ajax.get('/admin/subscriptions/plans.json', {
            params: { provider: 'google_play' }
        })
        activePlanId.value = plansData?.meta?.active_plan_id || ''
    } catch (e) {
        console.warn('Failed to load Google Play product:', e)
        plans.value = []
    }
}

const onProviderChange = async () => {
    // Reset plans and active plan when provider changes
    plans.value = []
    activePlanId.value = ''
    await fetchPlans()
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

const selectPlan = async (plan) => {
    try {
        const planId = plan.id || plan.product_id
        await ajax.post(`/admin/subscriptions/plans/${planId}/select`, {
            plan_id: planId,
            provider: selectedProviderKey.value
        })
        activePlanId.value = String(planId)
        error.value = ''
    } catch (e) {
        error.value = e?.response?.data?.error || 'Failed to select plan'
    }
}

const createPlan = async () => {
    try {
        await ajax.post('/admin/subscriptions/plans', {
            ...planForm.value,
            provider: selectedProviderKey.value
        })
        await fetchPlans()
        planForm.value.reason = 'Monthly Subscription Plan'
        error.value = ''
    } catch (e) {
        error.value = e?.response?.data?.error || 'Failed to create plan'
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

const grantSubscription = async (sub) => {
    const days = Number(sub._grantDays || 30)
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

const statusBadgeClass = (status) => {
    const v = (status || '').toLowerCase()
    if (['active', 'approved'].includes(v)) return 'is-active'
    if (['pending', 'in_process'].includes(v)) return 'is-pending'
    if (['cancelled', 'canceled', 'rejected'].includes(v)) return 'is-cancelled'
    return 'is-neutral'
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
        try { payload = JSON.parse(payload) } catch (e) { return payload }
    }
    return JSON.stringify(payload, null, 2)
}

const formatProvider = (provider) => {
    if (!provider) return 'N/A'
    const opt = providerOptions.value.find((c) => c.key === String(provider))
    if (opt) return opt.label

    // Use same formatting logic as provider-ui.ts
    return String(provider)
        .split('_')
        .map((token) => token.charAt(0).toUpperCase() + token.slice(1))
        .join(' ')
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
.subscriptions-admin {
    display: flex;
    flex-direction: column;
    gap: 20px;
    padding: 20px 24px;
    max-width: 1200px;
    animation: fadeIn 0.2s ease;
}

@keyframes fadeIn {
    from {
        opacity: 0;
        transform: translateY(8px);
    }

    to {
        opacity: 1;
        transform: translateY(0);
    }
}

/* ── Header ──────────────────────────────────────────────────────────── */
.subscriptions-admin__header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 16px;
    padding-bottom: 20px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.06);
}

.subscriptions-admin__header-content {
    flex: 1;
}

.subscriptions-admin__title {
    display: flex;
    align-items: center;
    gap: 12px;
    font-size: 1.5rem;
    font-weight: 600;
    color: #fff;
    margin: 0 0 8px 0;
}

.subscriptions-admin__icon {
    color: var(--c-tertiary-400, #0095d9);
}

.subscriptions-admin__description {
    font-size: 0.85rem;
    color: rgba(255, 255, 255, 0.45);
    margin: 0;
}

/* ── Tabs ──────────────────────────────────────────────────────────── */
.subscriptions-admin__tabs {
    display: flex;
    gap: 4px;
    overflow-x: auto;
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    padding-bottom: 0px;
    margin-bottom: 8px;
}

.subscriptions-admin__tab {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 10px 16px;
    background: transparent;
    border: none;
    color: rgba(255, 255, 255, 0.5);
    font-size: 0.9rem;
    font-weight: 500;
    cursor: pointer;
    position: relative;
    border-bottom: 2px solid transparent;
    transition: all 0.2s ease;
}

.subscriptions-admin__tab:hover {
    color: rgba(255, 255, 255, 0.9);
}

.subscriptions-admin__tab--active {
    color: var(--c-tertiary-400, #0095d9);
    border-bottom-color: var(--c-tertiary-400, #0095d9);
}

/* ── Stats Cards ─────────────────────────────────────────────────────── */
.subscriptions-admin__stats {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 12px;
}

.subscriptions-admin__stat-card {
    display: flex;
    align-items: center;
    gap: 14px;
    padding: 16px;
    background: rgba(255, 255, 255, 0.03);
    border: 1px solid rgba(255, 255, 255, 0.06);
    border-radius: 8px;
    transition: all 0.15s ease;
}

.subscriptions-admin__stat-card:hover {
    background: rgba(255, 255, 255, 0.04);
}

.subscriptions-admin__stat-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 44px;
    height: 44px;
    border-radius: 8px;
    background: rgba(255, 255, 255, 0.06);
    color: rgba(255, 255, 255, 0.6);
}

.subscriptions-admin__stat-icon--active {
    background: rgba(30, 192, 138, 0.15);
    color: #1ec08a;
}

.subscriptions-admin__stat-icon--primary {
    background: rgba(0, 149, 217, 0.15);
    color: var(--c-tertiary-400, #0095d9);
}

.subscriptions-admin__stat-icon--pending {
    background: rgba(255, 193, 7, 0.15);
    color: #ffc107;
}

.subscriptions-admin__stat-icon--cancelled {
    background: rgba(255, 120, 120, 0.15);
    color: #ff7878;
}

.subscriptions-admin__stat-content {
    flex: 1;
}

.subscriptions-admin__stat-label {
    display: block;
    font-size: 0.75rem;
    color: rgba(255, 255, 255, 0.45);
    text-transform: uppercase;
    letter-spacing: 0.05em;
    font-weight: 500;
}

.subscriptions-admin__stat-value {
    display: block;
    font-size: 1.5rem;
    font-weight: 700;
    color: #fff;
    margin-top: 4px;
}

.subscriptions-admin__stat-value--small {
    font-size: 0.95rem;
    font-weight: 500;
    color: rgba(255, 255, 255, 0.9);
}

/* ── Cards & Misc ────────────────────────────────────────────────────── */
.subscriptions-admin__card {
    padding: 20px;
    background: rgba(255, 255, 255, 0.03);
    border: 1px solid rgba(255, 255, 255, 0.06);
    border-radius: 8px;
}

.subscriptions-admin__card-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 16px;
    margin-bottom: 20px;
}

.subscriptions-admin__card-title {
    display: flex;
    align-items: center;
    gap: 10px;
    font-size: 1.05rem;
    font-weight: 600;
    color: rgba(255, 255, 255, 0.9);
    margin: 0;
}

.subscriptions-admin__card-description {
    font-size: 0.8rem;
    color: rgba(255, 255, 255, 0.4);
    margin: 6px 0 0;
}

.subscriptions-admin__filters {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 14px;
}

.subscriptions-admin__field {
    display: flex;
    flex-direction: column;
    gap: 6px;
}

.subscriptions-admin__field--actions {
    justify-content: flex-end;
}

.subscriptions-admin__label {
    font-size: 0.75rem;
    font-weight: 500;
    color: rgba(255, 255, 255, 0.5);
    text-transform: uppercase;
    letter-spacing: 0.05em;
}

.subscriptions-admin__input,
.subscriptions-admin__select {
    width: 100%;
    padding: 9px 12px;
    border-radius: 6px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    background: rgba(0, 0, 0, 0.25);
    color: rgba(255, 255, 255, 0.9);
    font-size: 0.875rem;
    transition: border-color 0.15s ease;
}

.subscriptions-admin__input:focus,
.subscriptions-admin__select:focus {
    outline: none;
    border-color: var(--c-tertiary-400, #0095d9);
}

.subscriptions-admin__toggle {
    display: flex;
    align-items: center;
    gap: 8px;
    cursor: pointer;
}

.subscriptions-admin__toggle input[type="checkbox"] {
    display: none;
}

.subscriptions-admin__toggle-label {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 14px;
    border-radius: 6px;
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.65);
    font-size: 0.825rem;
    font-weight: 500;
    transition: all 0.15s ease;
}

.subscriptions-admin__toggle:hover .subscriptions-admin__toggle-label {
    background: rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.9);
}

.subscriptions-admin__loading,
.subscriptions-admin__empty {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 48px 20px;
    text-align: center;
    color: rgba(255, 255, 255, 0.45);
}

.subscriptions-admin__loading-icon {
    animation: spin 1s linear infinite;
    color: var(--c-tertiary-400, #0095d9);
    margin-bottom: 12px;
}

@keyframes spin {
    from {
        transform: rotate(0deg);
    }

    to {
        transform: rotate(360deg);
    }
}

.subscriptions-admin__empty-icon {
    color: rgba(255, 255, 255, 0.15);
    margin-bottom: 16px;
}

.subscriptions-admin__empty-title {
    font-size: 1rem;
    font-weight: 500;
    color: rgba(255, 255, 255, 0.6);
    margin: 0 0 6px 0;
}

.subscriptions-admin__empty-description {
    font-size: 0.8rem;
    color: rgba(255, 255, 255, 0.35);
    margin: 0;
}

.subscriptions-admin__list {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.subscription__card {
    padding: 14px 16px;
    background: rgba(255, 255, 255, 0.03);
    border: 1px solid rgba(255, 255, 255, 0.06);
    border-radius: 8px;
    transition: all 0.15s ease;
}

.subscription__card:hover {
    background: rgba(255, 255, 255, 0.04);
}

.subscription__header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 12px;
    margin-bottom: 10px;
}

.subscription__info {
    display: flex;
    align-items: center;
    gap: 12px;
    flex-wrap: wrap;
}

.subscription__id {
    font-size: 0.8rem;
    font-weight: 600;
    color: rgba(255, 255, 255, 0.5);
}

.subscription__user {
    font-size: 0.875rem;
    font-weight: 500;
    color: rgba(255, 255, 255, 0.9);
}

.subscription__date {
    display: flex;
    align-items: center;
    gap: 5px;
    font-size: 0.75rem;
    color: rgba(255, 255, 255, 0.4);
}

.subscription__badge {
    padding: 4px 10px;
    border-radius: 10px;
    font-size: 0.7rem;
    font-weight: 600;
    text-transform: uppercase;
}

.subscription__badge.is-active {
    background: rgba(30, 192, 138, 0.15);
    color: #1ec08a;
}

.subscription__badge.is-pending {
    background: rgba(255, 193, 7, 0.15);
    color: #ffc107;
}

.subscription__badge.is-cancelled {
    background: rgba(255, 120, 120, 0.15);
    color: #ff7878;
}

.subscription__badge.is-neutral {
    background: rgba(148, 163, 184, 0.15);
    color: #94a3b8;
}

.subscription__meta {
    display: flex;
    gap: 16px;
    margin-bottom: 12px;
}

.subscription__meta-item {
    display: flex;
    align-items: center;
    gap: 6px;
    font-size: 0.775rem;
    color: rgba(255, 255, 255, 0.45);
}

.subscription__actions {
    display: flex;
    gap: 8px;
    align-items: center;
}

/* Grant group styling */
.subscription__grant-group {
    display: flex;
    align-items: stretch;
    border-radius: 6px;
    overflow: hidden;
    border: 1px solid rgba(255, 255, 255, 0.08);
    background: rgba(255, 255, 255, 0.02);
}

.subscription__grant-select {
    background: transparent;
    border: none;
    color: rgba(255, 255, 255, 0.8);
    padding: 0 8px;
    font-size: 0.8rem;
    cursor: pointer;
    outline: none;
    border-right: 1px solid rgba(255, 255, 255, 0.08);
}

.subscription__grant-select option {
    background: #1a1a1a;
    color: #fff;
}

.subscription__grant-group .subscription__btn {
    border: none;
    border-radius: 0;
    background: transparent;
}

.subscription__grant-group .subscription__btn:hover {
    background: rgba(255, 255, 255, 0.05);
}

.subscription__btn {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 6px 12px;
    border-radius: 6px;
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.65);
    font-size: 0.8rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.15s ease;
}

.subscription__btn:hover:not(:disabled) {
    background: rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.9);
}

.subscription__btn:disabled {
    opacity: 0.4;
    cursor: not-allowed;
}

.subscription__btn--danger {
    background: rgba(255, 120, 120, 0.1);
    border-color: rgba(255, 120, 120, 0.2);
    color: #ff7878;
}

.subscription__btn--danger:hover:not(:disabled) {
    background: rgba(255, 120, 120, 0.18);
}

/* ── Plans ───────────────────────────────────────────────────────────── */
.subscriptions-admin__plans {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.plan__card {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 16px;
    padding: 14px 16px;
    background: rgba(255, 255, 255, 0.03);
    border: 1px solid rgba(255, 255, 255, 0.06);
    border-radius: 8px;
    transition: all 0.15s ease;
}

.plan__card:hover {
    background: rgba(255, 255, 255, 0.04);
}

.plan__card--active {
    border-color: var(--c-tertiary-400, #0095d9);
    background: rgba(0, 149, 217, 0.06);
}

.plan__content {
    flex: 1;
}

.plan__header {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 8px;
}

.plan__name {
    font-size: 0.95rem;
    font-weight: 600;
    color: rgba(255, 255, 255, 0.9);
    margin: 0;
}

.plan__badge {
    display: inline-flex;
    align-items: center;
    gap: 4px;
    padding: 3px 8px;
    border-radius: 10px;
    background: var(--c-tertiary-400, #0095d9);
    color: #fff;
    font-size: 0.675rem;
    font-weight: 600;
}

.plan__details {
    display: flex;
    gap: 16px;
    flex-wrap: wrap;
}

.plan__detail {
    display: flex;
    align-items: center;
    gap: 6px;
    font-size: 0.775rem;
    color: rgba(255, 255, 255, 0.45);
}

.plan__id {
    font-family: monospace;
}

.plan__actions {
    flex-shrink: 0;
}

.plan__btn {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 8px 16px;
    border-radius: 6px;
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.65);
    font-size: 0.825rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.15s ease;
}

.plan__btn:hover:not(:disabled) {
    background: rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.9);
}

.plan__btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
}

.plan__btn--active {
    background: var(--c-tertiary-400, #0095d9);
    border-color: var(--c-tertiary-400, #0095d9);
    color: #fff;
}

.subscriptions-admin__divider {
    display: flex;
    align-items: center;
    gap: 16px;
    margin: 24px 0;
}

.subscriptions-admin__divider::before,
.subscriptions-admin__divider::after {
    content: '';
    flex: 1;
    height: 1px;
    background: rgba(255, 255, 255, 0.06);
}

.subscriptions-admin__divider-text {
    font-size: 0.8rem;
    color: rgba(255, 255, 255, 0.4);
    white-space: nowrap;
}

.subscriptions-admin__provider-controls {
    display: flex;
    align-items: flex-end;
    gap: 16px;
    flex-wrap: wrap;
}

.subscriptions-admin__form-grid {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 14px;
}

.subscriptions-admin__form-actions {
    display: flex;
    justify-content: flex-end;
    margin-top: 16px;
}

.subscriptions-admin__info-box {
    display: flex;
    align-items: flex-start;
    gap: 16px;
    padding: 20px;
    background: rgba(255, 255, 255, 0.02);
    border: 1px solid rgba(255, 255, 255, 0.04);
    border-radius: 8px;
    margin-top: 20px;
}

.subscriptions-admin__info-box--plan {
    margin-top: 0;
    margin-bottom: 16px;
    background: rgba(0, 149, 217, 0.06);
    border-color: rgba(0, 149, 217, 0.12);
}

.subscriptions-admin__info-icon {
    color: var(--c-tertiary-400, #0095d9);
    flex-shrink: 0;
    margin-top: 2px;
}

.subscriptions-admin__info-content {
    flex: 1;
}

.subscriptions-admin__info-content h4 {
    font-size: 0.9rem;
    font-weight: 600;
    color: rgba(255, 255, 255, 0.9);
    margin: 0 0 8px 0;
}

.subscriptions-admin__info-content p {
    font-size: 0.8rem;
    color: rgba(255, 255, 255, 0.5);
    margin: 0;
    line-height: 1.5;
}

.subscriptions-admin__btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    padding: 8px 16px;
    border-radius: 6px;
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.65);
    font-size: 0.85rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.15s ease;
    white-space: nowrap;
}

.subscriptions-admin__btn:hover:not(:disabled) {
    background: rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.9);
}

.subscriptions-admin__btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
}

.subscriptions-admin__btn--primary {
    background: var(--c-tertiary-400, #0095d9);
    border-color: var(--c-tertiary-400, #0095d9);
    color: #fff;
}

.subscriptions-admin__btn--primary:hover:not(:disabled) {
    background: var(--c-tertiary-300, #00a8f0);
}

.subscriptions-admin__btn--spinning {
    animation: spin 1s linear infinite;
}

.subscriptions-admin__error {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 12px 16px;
    border-radius: 8px;
    background: rgba(255, 120, 120, 0.08);
    border: 1px solid rgba(255, 120, 120, 0.2);
    color: #ff9494;
    font-size: 0.85rem;
}

.subscriptions-admin__error-close {
    margin-left: auto;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 4px;
    border-radius: 4px;
    background: transparent;
    border: none;
    color: rgba(255, 148, 148, 0.7);
    cursor: pointer;
    transition: all 0.15s ease;
}

.subscriptions-admin__error-close:hover {
    background: rgba(255, 120, 120, 0.15);
    color: #ff9494;
}

/* ── Logs ───────────────────────────────────────────────────────────── */
.subscriptions-admin__logs {
    display: flex;
    flex-direction: column;
    gap: 10px;
}

.log__item {
    background: rgba(255, 255, 255, 0.02);
    border: 1px solid rgba(255, 255, 255, 0.05);
    border-radius: 8px;
    padding: 12px;
}

.log__header {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 8px;
    font-size: 0.8rem;
}

.log__provider {
    padding: 2px 6px;
    border-radius: 4px;
    font-weight: 600;
    text-transform: uppercase;
    background: rgba(255, 255, 255, 0.1);
    color: #ddd;
}

.log__provider--mercado_pago {
    background: rgba(0, 158, 227, 0.2);
    color: #009ee3;
}

.log__provider--lemon_squeezy {
    background: rgba(142, 67, 231, 0.2);
    color: #8e43e7;
}

.log__event {
    font-weight: 500;
    color: #fff;
}

.log__date {
    color: rgba(255, 255, 255, 0.4);
    margin-left: auto;
}

.log__status {
    font-family: monospace;
    font-size: 0.75rem;
    padding: 2px 6px;
    border-radius: 4px;
    margin-bottom: 8px;
    display: inline-block;
}

.status-ok {
    background: rgba(30, 192, 138, 0.1);
    color: #1ec08a;
}

.status-err {
    background: rgba(255, 120, 120, 0.1);
    color: #ff7878;
}

.log__details summary {
    font-size: 0.75rem;
    color: rgba(255, 255, 255, 0.5);
    cursor: pointer;
    padding: 4px 0;
    outline: none;
}

.log__pre {
    margin: 8px 0 0;
    padding: 12px;
    background: rgba(0, 0, 0, 0.4);
    border-radius: 6px;
    font-family: monospace;
    font-size: 0.75rem;
    color: #ccc;
    overflow-x: auto;
}

/* ── Manual Subscription ───────────────────────────────────────────── */
.subscriptions-admin__manual-section {
    margin-bottom: 8px;
}

.subscriptions-admin__manual-toggle {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 8px 12px;
    border-radius: 6px;
    background: rgba(255, 255, 255, 0.03);
    border: 1px dashed rgba(255, 255, 255, 0.15);
    color: rgba(255, 255, 255, 0.7);
    font-size: 0.85rem;
    cursor: pointer;
    width: 100%;
    text-align: left;
    transition: all 0.15s ease;
}

.subscriptions-admin__manual-toggle:hover {
    background: rgba(255, 255, 255, 0.06);
    border-color: rgba(255, 255, 255, 0.25);
    color: #fff;
}

.subscriptions-admin__manual-form {
    margin-top: 12px;
    padding: 16px;
    border-radius: 8px;
    background: rgba(0, 200, 83, 0.03);
    border: 1px solid rgba(0, 200, 83, 0.12);
}

.subscriptions-admin__user-results {
    margin-top: 4px;
    border-radius: 6px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    background: rgba(0, 0, 0, 0.6);
    overflow: hidden;
    max-height: 240px;
    overflow-y: auto;
}

.subscriptions-admin__user-result {
    display: flex;
    flex-direction: column;
    gap: 2px;
    width: 100%;
    padding: 8px 12px;
    border: none;
    background: transparent;
    color: rgba(255, 255, 255, 0.8);
    font-size: 0.85rem;
    text-align: left;
    cursor: pointer;
    transition: background 0.1s;
}

.subscriptions-admin__user-result:hover,
.subscriptions-admin__user-result--selected {
    background: rgba(255, 255, 255, 0.06);
}

.subscriptions-admin__user-result-name {
    font-weight: 600;
    color: #fff;
}

.subscriptions-admin__user-result-email {
    font-size: 0.75rem;
    color: rgba(255, 255, 255, 0.4);
}

.subscriptions-admin__user-selected {
    display: flex;
    align-items: center;
    gap: 6px;
    margin-top: 6px;
    padding: 6px 10px;
    border-radius: 6px;
    background: rgba(30, 192, 138, 0.1);
    color: #1ec08a;
    font-size: 0.85rem;
}

.subscriptions-admin__user-clear {
    display: flex;
    align-items: center;
    justify-content: center;
    margin-left: auto;
    padding: 2px;
    border: none;
    border-radius: 4px;
    background: transparent;
    color: rgba(255, 255, 255, 0.4);
    cursor: pointer;
    transition: all 0.1s;
}

.subscriptions-admin__user-clear:hover {
    background: rgba(255, 255, 255, 0.1);
    color: #fff;
}

@media (max-width: 1024px) {
    .subscriptions-admin__stats {
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }

    .subscriptions-admin__filters,
    .subscriptions-admin__form-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }
}

@media (max-width: 767px) {
    .subscriptions-admin {
        padding: 16px 12px;
    }

    .subscriptions-admin__header,
    .subscriptions-admin__card-header,
    .subscription__header {
        flex-direction: column;
        align-items: flex-start;
        gap: 12px;
    }

    .subscriptions-admin__actions,
    .subscriptions-admin__btn,
    .plan__actions,
    .plan__btn {
        width: 100%;
        justify-content: center;
    }

    .subscriptions-admin__stats,
    .subscriptions-admin__filters,
    .subscriptions-admin__form-grid {
        grid-template-columns: 1fr;
    }

    .plan__card {
        flex-direction: column;
        align-items: flex-start;
    }
}
</style>
