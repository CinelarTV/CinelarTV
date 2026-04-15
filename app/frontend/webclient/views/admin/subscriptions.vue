<template>
    <div class="subscriptions-admin">
        <!-- Header -->
        <div class="subscriptions-admin__header">
            <div class="subscriptions-admin__header-content">
                <h1 class="subscriptions-admin__title">
                    <CIcon icon="credit-card" :size="28" class="subscriptions-admin__icon" />
                    Subscriptions Manager
                </h1>
                <p class="subscriptions-admin__description">
                    Manage plans, monitor subscriptions, and handle administrative actions
                </p>
            </div>
            <div class="subscriptions-admin__actions">
                <button class="subscriptions-admin__btn" @click="refreshAll" :disabled="loading">
                    <CIcon icon="refresh-cw" :size="16" :class="{ 'subscriptions-admin__btn--spinning': loading }" />
                    Refresh All
                </button>
            </div>
        </div>

        <!-- Stats Cards -->
        <div class="subscriptions-admin__stats">
            <div class="subscriptions-admin__stat-card">
                <div class="subscriptions-admin__stat-icon">
                    <CIcon icon="users" :size="24" />
                </div>
                <div class="subscriptions-admin__stat-content">
                    <span class="subscriptions-admin__stat-label">Total Subscriptions</span>
                    <strong class="subscriptions-admin__stat-value">{{ subscriptions.length }}</strong>
                </div>
            </div>
            <div class="subscriptions-admin__stat-card">
                <div class="subscriptions-admin__stat-icon subscriptions-admin__stat-icon--active">
                    <CIcon icon="check-circle" :size="24" />
                </div>
                <div class="subscriptions-admin__stat-content">
                    <span class="subscriptions-admin__stat-label">Active</span>
                    <strong class="subscriptions-admin__stat-value">{{ activeSubscriptionsCount }}</strong>
                </div>
            </div>
            <div class="subscriptions-admin__stat-card">
                <div class="subscriptions-admin__stat-icon">
                    <CIcon icon="package" :size="24" />
                </div>
                <div class="subscriptions-admin__stat-content">
                    <span class="subscriptions-admin__stat-label">Available Plans</span>
                    <strong class="subscriptions-admin__stat-value">{{ plans.length }}</strong>
                </div>
            </div>
            <div class="subscriptions-admin__stat-card">
                <div class="subscriptions-admin__stat-icon subscriptions-admin__stat-icon--primary">
                    <CIcon icon="star" :size="24" />
                </div>
                <div class="subscriptions-admin__stat-content">
                    <span class="subscriptions-admin__stat-label">Active Plan</span>
                    <strong class="subscriptions-admin__stat-value subscriptions-admin__stat-value--small">{{
                        activePlanName }}</strong>
                </div>
            </div>
        </div>

        <!-- Filters Section -->
        <div class="subscriptions-admin__card">
            <div class="subscriptions-admin__card-header">
                <h2 class="subscriptions-admin__card-title">
                    <CIcon icon="filter" :size="20" />
                    Filters
                </h2>
                <p class="subscriptions-admin__card-description">
                    Refine subscriptions by user, status, and provider
                </p>
            </div>
            <div class="subscriptions-admin__filters">
                <div class="subscriptions-admin__field">
                    <label class="subscriptions-admin__label">Search</label>
                    <input v-model="filters.query" class="subscriptions-admin__input"
                        placeholder="Email, username or ID" @keyup.enter="fetchSubscriptions" />
                </div>
                <div class="subscriptions-admin__field">
                    <label class="subscriptions-admin__label">Status</label>
                    <select v-model="filters.status" class="subscriptions-admin__select" @change="fetchSubscriptions">
                        <option value="">All</option>
                        <option value="active">Active</option>
                        <option value="approved">Approved</option>
                        <option value="pending">Pending</option>
                        <option value="cancelled">Cancelled</option>
                    </select>
                </div>
                <div class="subscriptions-admin__field">
                    <label class="subscriptions-admin__label">Provider</label>
                    <select v-model="filters.provider" class="subscriptions-admin__select" @change="fetchSubscriptions">
                        <option value="">All</option>
                        <option value="mercado_pago">MercadoPago</option>
                    </select>
                </div>
                <div class="subscriptions-admin__field subscriptions-admin__field--actions">
                    <button class="subscriptions-admin__btn subscriptions-admin__btn--primary"
                        @click="fetchSubscriptions">
                        <CIcon icon="search" :size="16" />
                        Apply Filters
                    </button>
                </div>
            </div>
        </div>

        <!-- Subscriptions List -->
        <div class="subscriptions-admin__card">
            <div class="subscriptions-admin__card-header">
                <h2 class="subscriptions-admin__card-title">
                    <CIcon icon="list" :size="20" />
                    Subscriptions
                </h2>
                <p class="subscriptions-admin__card-description">
                    Manage user subscriptions and perform administrative actions
                </p>
            </div>

            <!-- Loading state -->
            <div v-if="loading" class="subscriptions-admin__loading">
                <CIcon icon="loader" :size="32" class="subscriptions-admin__loading-icon" />
                <p>Loading subscriptions...</p>
            </div>

            <!-- Empty state -->
            <div v-else-if="!subscriptions.length" class="subscriptions-admin__empty">
                <CIcon icon="inbox" :size="48" class="subscriptions-admin__empty-icon" />
                <p class="subscriptions-admin__empty-title">No subscriptions found</p>
                <p class="subscriptions-admin__empty-description">
                    No subscriptions match your current filters
                </p>
            </div>

            <!-- Subscriptions list -->
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
                            <span>{{ sub.provider || 'N/A' }}</span>
                        </div>
                        <div class="subscription__meta-item" v-if="sub.product_name">
                            <CIcon icon="package" :size="14" />
                            <span>{{ sub.product_name }}</span>
                        </div>
                    </div>
                    <div class="subscription__actions">
                        <button class="subscription__btn" @click="syncSubscription(sub)">
                            <CIcon icon="refresh-cw" :size="14" />
                            Sync
                        </button>
                        <button class="subscription__btn" @click="grantSubscription(sub)">
                            <CIcon icon="gift" :size="14" />
                            Grant 30d
                        </button>
                        <button class="subscription__btn subscription__btn--danger" @click="cancelSubscription(sub)">
                            <CIcon icon="x-circle" :size="14" />
                            Cancel
                        </button>
                    </div>
                </div>
            </div>
        </div>

        <!-- Plans Section -->
        <div class="subscriptions-admin__card">
            <div class="subscriptions-admin__card-header">
                <div>
                    <h2 class="subscriptions-admin__card-title">
                        <CIcon icon="package" :size="20" />
                        Plans
                    </h2>
                    <p class="subscriptions-admin__card-description">
                        Select a plan created from MercadoPago web interface or create a new one
                    </p>
                </div>
                <label class="subscriptions-admin__toggle">
                    <input type="checkbox" v-model="showAllPlans" @change="fetchPlans" />
                    <span class="subscriptions-admin__toggle-label">
                        <CIcon :icon="showAllPlans ? 'check-square' : 'square'" :size="18" />
                        Show all merchant plans
                    </span>
                </label>
            </div>

            <!-- Plans list -->
            <div v-if="!plans.length" class="subscriptions-admin__empty">
                <CIcon icon="package-x" :size="48" class="subscriptions-admin__empty-icon" />
                <p class="subscriptions-admin__empty-title">No plans available</p>
                <p class="subscriptions-admin__empty-description">
                    Create a plan from MercadoPago web interface or use the form below
                </p>
            </div>
            <div v-else class="subscriptions-admin__plans">
                <div v-for="plan in plans" :key="plan.id" class="plan__card"
                    :class="{ 'plan__card--active': String(plan.id) === String(activePlanId) }">
                    <div class="plan__content">
                        <div class="plan__header">
                            <h3 class="plan__name">{{ plan.reason }}</h3>
                            <span v-if="String(plan.id) === String(activePlanId)" class="plan__badge">
                                <CIcon icon="check" :size="14" />
                                Active
                            </span>
                        </div>
                        <div class="plan__details">
                            <div class="plan__detail">
                                <CIcon icon="dollar-sign" :size="14" />
                                <span>{{ plan.auto_recurring?.transaction_amount }} {{ plan.auto_recurring?.currency_id
                                    }}</span>
                            </div>
                            <div class="plan__detail">
                                <CIcon icon="calendar" :size="14" />
                                <span>{{ plan.auto_recurring?.frequency }} {{ plan.auto_recurring?.frequency_type
                                    }}</span>
                            </div>
                            <div class="plan__detail">
                                <CIcon icon="hash" :size="14" />
                                <span class="plan__id">ID: {{ plan.id }}</span>
                            </div>
                        </div>
                    </div>
                    <div class="plan__actions">
                        <button class="plan__btn"
                            :class="{ 'plan__btn--active': String(plan.id) === String(activePlanId) }"
                            @click="selectPlan(plan)" :disabled="String(plan.id) === String(activePlanId)">
                            <CIcon :icon="String(plan.id) === String(activePlanId) ? 'check-circle' : 'arrow-right'"
                                :size="16" />
                            {{ String(plan.id) === String(activePlanId) ? 'Active Plan' : 'Select Plan' }}
                        </button>
                    </div>
                </div>
            </div>

            <!-- Create Plan Form -->
            <div class="subscriptions-admin__divider">
                <span class="subscriptions-admin__divider-text">Or create a new plan</span>
            </div>

            <form class="subscriptions-admin__form" @submit.prevent="createPlan">
                <div class="subscriptions-admin__form-grid">
                    <div class="subscriptions-admin__field">
                        <label class="subscriptions-admin__label">Plan Name</label>
                        <input v-model="planForm.reason" class="subscriptions-admin__input"
                            placeholder="e.g., Monthly Plan" required />
                    </div>
                    <div class="subscriptions-admin__field">
                        <label class="subscriptions-admin__label">Amount</label>
                        <input v-model.number="planForm.amount" type="number" step="0.01" min="0"
                            class="subscriptions-admin__input" required />
                    </div>
                    <div class="subscriptions-admin__field">
                        <label class="subscriptions-admin__label">Currency</label>
                        <select v-model="planForm.currency_id" class="subscriptions-admin__select">
                            <option value="UYU">UYU - Uruguayan Peso</option>
                            <option value="USD">USD - US Dollar</option>
                            <option value="ARS">ARS - Argentine Peso</option>
                            <option value="BRL">BRL - Brazilian Real</option>
                        </select>
                    </div>
                    <div class="subscriptions-admin__field">
                        <label class="subscriptions-admin__label">Billing Frequency</label>
                        <select v-model.number="planForm.frequency" class="subscriptions-admin__select">
                            <option :value="1">Monthly</option>
                            <option :value="3">Quarterly</option>
                            <option :value="6">Semi-annual</option>
                            <option :value="12">Annual</option>
                        </select>
                    </div>
                </div>
                <div class="subscriptions-admin__form-actions">
                    <button class="subscriptions-admin__btn subscriptions-admin__btn--primary" type="submit">
                        <CIcon icon="plus" :size="16" />
                        Create Plan
                    </button>
                </div>
            </form>
        </div>

        <!-- Error Display -->
        <div v-if="error" class="subscriptions-admin__error">
            <CIcon icon="alert-circle" :size="18" />
            {{ error }}
            <button class="subscriptions-admin__error-close" @click="error = ''">
                <CIcon icon="x" :size="16" />
            </button>
        </div>
    </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { ajax } from '../../lib/Ajax'
import CIcon from '@/components/c-icon.vue'

const loading = ref(false)
const error = ref('')
const subscriptions = ref([])
const plans = ref([])
const showAllPlans = ref(false)
const activePlanId = ref('')

const filters = ref({
    query: '',
    status: '',
    provider: ''
})

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

const activePlanName = computed(() => {
    if (!activePlanId.value) {
        return 'No plan selected'
    }

    const activePlan = plans.value.find((plan) => String(plan.id) === String(activePlanId.value))
    return activePlan?.reason || `Plan ${activePlanId.value}`
})

const refreshAll = async () => {
    await Promise.all([
        fetchSubscriptions(),
        fetchPlans()
    ])
}

const fetchSubscriptions = async () => {
    loading.value = true
    error.value = ''

    try {
        const { data } = await ajax.get('/admin/subscriptions.json', { params: filters.value })
        subscriptions.value = data?.data || []
    } catch (e) {
        error.value = e?.response?.data?.error || 'Failed to load subscriptions'
    } finally {
        loading.value = false
    }
}

const fetchPlans = async () => {
    try {
        const { data } = await ajax.get('/admin/subscriptions/plans.json', {
            params: { managed_only: !showAllPlans.value }
        })
        plans.value = data?.data || []
        activePlanId.value = data?.meta?.active_plan_id || ''
    } catch (e) {
        error.value = e?.response?.data?.error || 'Failed to load plans'
    }
}

const selectPlan = async (plan) => {
    try {
        await ajax.post(`/admin/subscriptions/plans/${plan.id}/select`, { plan })
        activePlanId.value = String(plan.id)
        error.value = ''
    } catch (e) {
        error.value = e?.response?.data?.error || 'Failed to select plan'
    }
}

const createPlan = async () => {
    try {
        await ajax.post('/admin/subscriptions/plans', planForm.value)
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
        error.value = ''
    } catch (e) {
        error.value = e?.response?.data?.error || 'Failed to sync'
    }
}

const grantSubscription = async (sub) => {
    try {
        await ajax.post(`/admin/subscriptions/${sub.id}/grant`, { days: 30 })
        await fetchSubscriptions()
        error.value = ''
    } catch (e) {
        error.value = e?.response?.data?.error || 'Failed to grant access'
    }
}

const cancelSubscription = async (sub) => {
    if (!confirm('Are you sure you want to cancel this subscription?')) {
        return
    }

    try {
        await ajax.post(`/admin/subscriptions/${sub.id}/cancel`)
        await fetchSubscriptions()
        error.value = ''
    } catch (e) {
        error.value = e?.response?.data?.error || 'Failed to cancel'
    }
}

const statusBadgeClass = (status) => {
    const value = (status || '').toLowerCase()
    if (['active', 'approved'].includes(value)) {
        return 'is-active'
    }
    if (['pending', 'in_process'].includes(value)) {
        return 'is-pending'
    }
    if (['cancelled', 'canceled', 'rejected'].includes(value)) {
        return 'is-cancelled'
    }
    return 'is-neutral'
}

const formatDate = (value) => {
    if (!value) {
        return '-'
    }

    const date = new Date(value)
    if (Number.isNaN(date.getTime())) {
        return '-'
    }

    return date.toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric'
    })
}

onMounted(async () => {
    await refreshAll()
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

.subscriptions-admin__actions {
    display: flex;
    gap: 8px;
}

/* ── Stats Cards ─────────────────────────────────────────────────────── */
.subscriptions-admin__stats {
    display: grid;
    grid-template-columns: repeat(4, minmax(0, 1fr));
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

/* ── Cards ───────────────────────────────────────────────────────────── */
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

/* ── Filters ─────────────────────────────────────────────────────────── */
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

.subscriptions-admin__input::placeholder {
    color: rgba(255, 255, 255, 0.3);
}

/* ── Toggle ──────────────────────────────────────────────────────────── */
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

/* ── Loading & Empty States ──────────────────────────────────────────── */
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

/* ── Subscriptions List ──────────────────────────────────────────────── */
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
    letter-spacing: 0.03em;
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

.subscription__btn:hover {
    background: rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.9);
}

.subscription__btn--danger {
    background: rgba(255, 120, 120, 0.1);
    border-color: rgba(255, 120, 120, 0.2);
    color: #ff7878;
}

.subscription__btn--danger:hover {
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

/* ── Divider ─────────────────────────────────────────────────────────── */
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

/* ── Form ────────────────────────────────────────────────────────────── */
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

/* ── Buttons ─────────────────────────────────────────────────────────── */
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

/* ── Error ───────────────────────────────────────────────────────────── */
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

/* ── Mobile Responsive ───────────────────────────────────────────────── */
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

    .subscriptions-admin__header {
        flex-direction: column;
        gap: 12px;
    }

    .subscriptions-admin__actions {
        width: 100%;
    }

    .subscriptions-admin__btn {
        width: 100%;
        justify-content: center;
    }

    .subscriptions-admin__stats {
        grid-template-columns: 1fr;
    }

    .subscriptions-admin__filters,
    .subscriptions-admin__form-grid {
        grid-template-columns: 1fr;
    }

    .subscriptions-admin__card-header {
        flex-direction: column;
        align-items: flex-start;
        gap: 12px;
    }

    .subscription__header {
        flex-direction: column;
        align-items: flex-start;
        gap: 10px;
    }

    .plan__card {
        flex-direction: column;
        align-items: flex-start;
    }

    .plan__actions {
        width: 100%;
    }

    .plan__btn {
        width: 100%;
        justify-content: center;
    }
}
</style>
