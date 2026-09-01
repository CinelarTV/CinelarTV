<template>
    <div class="webhook-logs-container">
        <!-- Header -->
        <div class="webhook-logs__header">
            <div class="webhook-logs__header-content">
                <h2 class="webhook-logs__title">
                    <CIcon icon="webhook" :size="24" class="webhook-logs__icon" />
                    Webhook Logs
                </h2>
                <p class="webhook-logs__description">
                    Monitor and inspect recent webhook event deliveries and their payloads
                </p>
            </div>
            <div class="webhook-logs__actions">
                <button class="webhook-logs__btn" @click="testWebhook" :disabled="testingWebhook">
                    <CIcon icon="test-tube" :size="18" :class="{ 'webhook-logs__btn--spinning': testingWebhook }" />
                    <span>{{ testingWebhook ? 'Testing...' : 'Test Webhook' }}</span>
                </button>
                <button class="webhook-logs__btn webhook-logs__btn--primary" @click="fetchLogs" :disabled="loading">
                    <CIcon icon="refresh-cw" :size="18" :class="{ 'webhook-logs__btn--spinning': loading }" />
                    <span>{{ loading ? 'Loading...' : 'Refresh' }}</span>
                </button>
            </div>
        </div>

        <!-- Test webhook result -->
        <div v-if="testResult" class="webhook-logs__test-result">
            <div class="webhook-logs__test-result-header">
                <CIcon icon="check-circle" :size="20" class="webhook-logs__test-result-icon" />
                <h3 class="webhook-logs__test-result-title">Webhook Test Result</h3>
                <button class="webhook-logs__test-result-close" @click="testResult = null">
                    <CIcon icon="x" :size="16" />
                </button>
            </div>
            <pre class="webhook-logs__test-result-data">{{ JSON.stringify(testResult, null, 2) }}</pre>
        </div>

        <!-- Empty state -->
        <div v-if="!loading && logs && logs.length === 0" class="webhook-logs__empty">
            <CIcon icon="inbox" :size="48" class="webhook-logs__empty-icon" />
            <p class="webhook-logs__empty-title">No webhook logs found</p>
            <p class="webhook-logs__empty-description">
                Webhook events will appear here once they are triggered
            </p>
        </div>

        <!-- Logs list -->
        <div v-else-if="!loading && logs && logs.length > 0" class="webhook-logs__list">
            <div v-for="(log, index) in logs" :key="log.id || index" class="webhook-log__card">
                <div class="webhook-log__card-header">
                    <div class="webhook-log__event-info">
                        <span :class="['webhook-log__provider-badge', `webhook-log__provider-badge--${log.provider_key}`]">
                            {{ log.provider_key }}
                        </span>
                        <span class="webhook-log__event-name">{{ log.event_type }}</span>
                        <span :class="['webhook-log__status-badge', `webhook-log__status-badge--${log.status}`]">
                            {{ log.status }}
                        </span>
                        <span v-if="log.received_at" class="webhook-log__timestamp">
                            <CIcon icon="clock" :size="14" />
                            {{ formatTimestamp(log.received_at) }}
                        </span>
                    </div>
                    <div class="webhook-log__actions">
                        <button class="webhook-log__copy-btn" @click="copyPayload(JSON.stringify(log))"
                            title="Copy full log">
                            <CIcon icon="copy" :size="14" />
                        </button>
                        <button class="webhook-log__toggle" @click="togglePayload(index)">
                            <CIcon :icon="expandedIndex === index ? 'chevron-up' : 'chevron-down'" :size="18" />
                            <span>{{ expandedIndex === index ? 'Hide' : 'Show' }} Payload</span>
                        </button>
                    </div>
                </div>

                <!-- Metadata row -->
                <div class="webhook-log__meta">
                    <span v-if="log.resource_id" class="webhook-log__meta-item">
                        <CIcon icon="link" :size="12" />
                        {{ log.resource_id }}
                    </span>
                    <span v-if="log.provider_event_id" class="webhook-log__meta-item">
                        <CIcon icon="hash" :size="12" />
                        {{ log.provider_event_id }}
                    </span>
                    <span v-if="log.processing_error" class="webhook-log__meta-item webhook-log__meta-item--error">
                        <CIcon icon="alert-triangle" :size="12" />
                        {{ log.processing_error }}
                    </span>
                </div>

                <!-- Expandable payload -->
                <div v-show="expandedIndex === index" class="webhook-log__payload-wrapper">
                    <div class="webhook-log__payload">
                        <pre>{{ formatPayload(log.payload) }}</pre>
                    </div>
                    <button class="webhook-log__copy-btn webhook-log__copy-btn--full" @click="copyPayload(log.payload)">
                        <CIcon icon="copy" :size="14" />
                        Copy Payload
                    </button>
                </div>
            </div>
        </div>

        <!-- Loading state -->
        <div v-if="loading" class="webhook-logs__loading">
            <CIcon icon="loader" :size="32" class="webhook-logs__loading-icon" />
            <p>Loading webhook logs...</p>
        </div>

        <!-- Pagination -->
        <div v-if="!loading && meta && meta.total_pages > 1" class="webhook-logs__pagination">
            <button
                class="webhook-logs__page-btn"
                :disabled="meta.page <= 1"
                @click="goToPage(1)"
            >
                <CIcon icon="chevrons-left" :size="16" />
            </button>
            <button
                class="webhook-logs__page-btn"
                :disabled="meta.page <= 1"
                @click="goToPage(meta.page - 1)"
            >
                <CIcon icon="chevron-left" :size="16" />
            </button>

            <template v-for="p in visiblePages" :key="p">
                <span v-if="p === '...'" class="webhook-logs__page-ellipsis">...</span>
                <button
                    v-else
                    :class="['webhook-logs__page-btn', 'webhook-logs__page-btn--number', { 'webhook-logs__page-btn--active': p === meta.page }]"
                    @click="goToPage(p)"
                >
                    {{ p }}
                </button>
            </template>

            <button
                class="webhook-logs__page-btn"
                :disabled="meta.page >= meta.total_pages"
                @click="goToPage(meta.page + 1)"
            >
                <CIcon icon="chevron-right" :size="16" />
            </button>
            <button
                class="webhook-logs__page-btn"
                :disabled="meta.page >= meta.total_pages"
                @click="goToPage(meta.total_pages)"
            >
                <CIcon icon="chevrons-right" :size="16" />
            </button>

            <span class="webhook-logs__page-info">
                Page {{ meta.page }} of {{ meta.total_pages }} ({{ meta.total }} events)
            </span>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ajax } from '../../../lib/Ajax'
import CIcon from '@/components/c-icon.vue'

onMounted(() => {
    fetchLogs()
})

const logs = ref(null)
const meta = ref(null)
const loading = ref(false)
const expandedIndex = ref(-1)
const testingWebhook = ref(false)
const testResult = ref(null)
const currentPage = ref(1)

const visiblePages = computed(() => {
    if (!meta.value) return []
    const { page, total_pages } = meta.value
    if (total_pages <= 7) {
        return Array.from({ length: total_pages }, (_, i) => i + 1)
    }
    const pages = []
    if (page <= 4) {
        for (let i = 1; i <= 5; i++) pages.push(i)
        pages.push('...', total_pages)
    } else if (page >= total_pages - 3) {
        pages.push(1, '...')
        for (let i = total_pages - 4; i <= total_pages; i++) pages.push(i)
    } else {
        pages.push(1, '...', page - 1, page, page + 1, '...', total_pages)
    }
    return pages
})

const fetchLogs = async () => {
    loading.value = true
    try {
        const response = await ajax.get('/admin/webhooks/logs.json', {
            params: { page: currentPage.value, per_page: 25 }
        })
        logs.value = response.data.data
        meta.value = response.data.meta
    } catch (error) {
        console.error('Failed to fetch webhook logs:', error)
    } finally {
        loading.value = false
    }
}

const goToPage = (page) => {
    currentPage.value = page
    expandedIndex.value = -1
    fetchLogs()
}

const togglePayload = (index) => {
    expandedIndex.value = expandedIndex.value === index ? -1 : index
}

const formatPayload = (payload) => {
    if (!payload) return 'No payload'
    try {
        const parsedPayload = typeof payload === 'string' ? JSON.parse(payload) : payload
        return JSON.stringify(parsedPayload, null, 2)
    } catch (error) {
        return payload
    }
}

const formatTimestamp = (timestamp) => {
    const date = new Date(timestamp)
    return date.toLocaleString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
    })
}

const copyPayload = async (payload) => {
    try {
        const text = typeof payload === 'string' ? payload : JSON.stringify(payload, null, 2)
        await navigator.clipboard.writeText(text)
    } catch (error) {
        console.error('Failed to copy payload:', error)
    }
}

const testWebhook = async () => {
    testingWebhook.value = true
    testResult.value = null
    try {
        const response = await ajax.post('/admin/subscriptions/webhooks/test.json')
        testResult.value = response.data
    } catch (error) {
        console.error('Webhook test failed:', error)
        testResult.value = { error: error?.response?.data?.error || 'Webhook test failed' }
    } finally {
        testingWebhook.value = false
    }
}
</script>

<style scoped>
.webhook-logs-container {
    animation: fadeIn 0.2s ease;
}

@keyframes fadeIn {
    from { opacity: 0; transform: translateY(8px); }
    to { opacity: 1; transform: translateY(0); }
}

/* ── Header ──────────────────────────────────────────────────────────── */
.webhook-logs__header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 16px;
    margin-bottom: 24px;
    padding-bottom: 20px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.06);
}

.webhook-logs__header-content { flex: 1; }

.webhook-logs__title {
    display: flex;
    align-items: center;
    gap: 12px;
    font-size: 1.25rem;
    font-weight: 600;
    color: #fff;
    margin: 0 0 8px 0;
}

.webhook-logs__icon { color: var(--c-tertiary-400, #0095d9); }

.webhook-logs__description {
    font-size: 0.8rem;
    color: rgba(255, 255, 255, 0.4);
    margin: 0;
}

.webhook-logs__actions { display: flex; gap: 8px; }

/* ── Test Result ─────────────────────────────────────────────────────── */
.webhook-logs__test-result {
    margin-bottom: 20px;
    padding: 16px;
    background: rgba(30, 192, 138, 0.08);
    border: 1px solid rgba(30, 192, 138, 0.2);
    border-radius: 8px;
}

.webhook-logs__test-result-header {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 12px;
}

.webhook-logs__test-result-icon { color: #1ec08a; }

.webhook-logs__test-result-title {
    flex: 1;
    font-size: 1rem;
    font-weight: 600;
    color: #fff;
    margin: 0;
}

.webhook-logs__test-result-close {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 4px;
    border-radius: 4px;
    background: transparent;
    border: none;
    color: rgba(255, 255, 255, 0.5);
    cursor: pointer;
    transition: all 0.15s ease;
}

.webhook-logs__test-result-close:hover {
    background: rgba(255, 255, 255, 0.1);
    color: #fff;
}

.webhook-logs__test-result-data {
    background: rgba(0, 0, 0, 0.3);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 6px;
    padding: 12px;
    overflow: auto;
    max-height: 400px;
    font-family: 'Fira Code', 'Consolas', monospace;
    font-size: 0.8rem;
    line-height: 1.5;
    color: rgba(255, 255, 255, 0.85);
    margin: 0;
}

/* ── Empty State ─────────────────────────────────────────────────────── */
.webhook-logs__empty {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 60px 20px;
    text-align: center;
}

.webhook-logs__empty-icon {
    color: rgba(255, 255, 255, 0.15);
    margin-bottom: 16px;
}

.webhook-logs__empty-title {
    font-size: 1rem;
    font-weight: 500;
    color: rgba(255, 255, 255, 0.6);
    margin: 0 0 6px 0;
}

.webhook-logs__empty-description {
    font-size: 0.8rem;
    color: rgba(255, 255, 255, 0.35);
    margin: 0;
}

/* ── Logs List ───────────────────────────────────────────────────────── */
.webhook-logs__list {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.webhook-log__card {
    padding: 14px 16px;
    background: rgba(255, 255, 255, 0.03);
    border: 1px solid rgba(255, 255, 255, 0.06);
    border-radius: 8px;
    transition: all 0.15s ease;
}

.webhook-log__card:hover { background: rgba(255, 255, 255, 0.04); }

.webhook-log__card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 12px;
}

.webhook-log__event-info {
    display: flex;
    align-items: center;
    gap: 10px;
    flex: 1;
    min-width: 0;
    flex-wrap: wrap;
}

/* Provider badges */
.webhook-log__provider-badge {
    font-size: 0.7rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    padding: 3px 8px;
    border-radius: 4px;
    white-space: nowrap;
}

.webhook-log__provider-badge--mercadopago {
    background: rgba(0, 155, 255, 0.15);
    color: #009bff;
}

.webhook-log__provider-badge--paypal {
    background: rgba(0, 48, 135, 0.2);
    color: #0070ba;
}

.webhook-log__provider-badge--stripe {
    background: rgba(99, 91, 255, 0.15);
    color: #635bff;
}

.webhook-log__provider-badge--default {
    background: rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.6);
}

/* Event name */
.webhook-log__event-name {
    font-size: 0.8rem;
    font-weight: 500;
    color: rgba(255, 255, 255, 0.8);
    font-family: 'Fira Code', 'Consolas', monospace;
}

/* Status badges */
.webhook-log__status-badge {
    font-size: 0.7rem;
    font-weight: 600;
    padding: 2px 6px;
    border-radius: 4px;
    white-space: nowrap;
}

.webhook-log__status-badge--200 {
    background: rgba(30, 192, 138, 0.15);
    color: #1ec08a;
}

.webhook-log__status-badge--202 {
    background: rgba(0, 149, 217, 0.15);
    color: #0095d9;
}

.webhook-log__status-badge--500 {
    background: rgba(224, 49, 49, 0.15);
    color: #e03131;
}

.webhook-log__timestamp {
    display: flex;
    align-items: center;
    gap: 6px;
    font-size: 0.75rem;
    color: rgba(255, 255, 255, 0.4);
    white-space: nowrap;
}

.webhook-log__actions { display: flex; gap: 8px; align-items: center; }

/* Meta row */
.webhook-log__meta {
    display: flex;
    align-items: center;
    gap: 16px;
    margin-top: 8px;
    flex-wrap: wrap;
}

.webhook-log__meta-item {
    display: flex;
    align-items: center;
    gap: 5px;
    font-size: 0.72rem;
    color: rgba(255, 255, 255, 0.35);
    font-family: 'Fira Code', 'Consolas', monospace;
}

.webhook-log__meta-item--error {
    color: rgba(224, 49, 49, 0.8);
}

/* Copy / Toggle buttons */
.webhook-log__copy-btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    padding: 6px;
    border-radius: 6px;
    background: transparent;
    border: none;
    color: rgba(255, 255, 255, 0.5);
    cursor: pointer;
    transition: all 0.15s ease;
}

.webhook-log__copy-btn:hover {
    background: rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.9);
}

.webhook-log__toggle {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 6px 12px;
    border-radius: 6px;
    background: rgba(255, 255, 255, 0.05);
    border: none;
    color: rgba(255, 255, 255, 0.6);
    font-size: 0.8rem;
    cursor: pointer;
    transition: all 0.15s ease;
    white-space: nowrap;
}

.webhook-log__toggle:hover {
    background: rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.9);
}

/* ── Payload Section ─────────────────────────────────────────────────── */
.webhook-log__payload-wrapper {
    margin-top: 12px;
    padding-top: 12px;
    border-top: 1px solid rgba(255, 255, 255, 0.06);
}

.webhook-log__payload {
    background: rgba(0, 0, 0, 0.3);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 6px;
    padding: 12px;
    overflow-x: auto;
    max-height: 400px;
    overflow-y: auto;
    margin-bottom: 8px;
}

.webhook-log__payload pre {
    margin: 0;
    font-family: 'Fira Code', 'Consolas', monospace;
    font-size: 0.8rem;
    line-height: 1.5;
    color: rgba(255, 255, 255, 0.85);
    white-space: pre;
}

.webhook-log__copy-btn--full {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    padding: 6px 12px;
    border-radius: 6px;
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.6);
    font-size: 0.75rem;
    cursor: pointer;
    transition: all 0.15s ease;
}

.webhook-log__copy-btn--full:hover {
    background: rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.9);
}

/* ── Pagination ──────────────────────────────────────────────────────── */
.webhook-logs__pagination {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 4px;
    margin-top: 24px;
    padding-top: 20px;
    border-top: 1px solid rgba(255, 255, 255, 0.06);
    flex-wrap: wrap;
}

.webhook-logs__page-btn {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-width: 32px;
    height: 32px;
    padding: 0 8px;
    border-radius: 6px;
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.6);
    font-size: 0.8rem;
    cursor: pointer;
    transition: all 0.15s ease;
}

.webhook-logs__page-btn:hover:not(:disabled):not(.webhook-logs__page-btn--active) {
    background: rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.9);
}

.webhook-logs__page-btn:disabled {
    opacity: 0.3;
    cursor: not-allowed;
}

.webhook-logs__page-btn--active {
    background: var(--c-tertiary-400, #0095d9);
    border-color: var(--c-tertiary-400, #0095d9);
    color: #fff;
}

.webhook-logs__page-btn--number {
    font-variant-numeric: tabular-nums;
}

.webhook-logs__page-ellipsis {
    color: rgba(255, 255, 255, 0.3);
    padding: 0 4px;
    font-size: 0.8rem;
}

.webhook-logs__page-info {
    margin-left: 12px;
    font-size: 0.75rem;
    color: rgba(255, 255, 255, 0.35);
}

/* ── Loading State ───────────────────────────────────────────────────── */
.webhook-logs__loading {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 60px 20px;
    color: rgba(255, 255, 255, 0.5);
    font-size: 0.85rem;
}

.webhook-logs__loading-icon {
    animation: spin 1s linear infinite;
    color: var(--c-tertiary-400, #0095d9);
    margin-bottom: 12px;
}

/* ── Buttons ─────────────────────────────────────────────────────────── */
.webhook-logs__btn {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 8px 16px;
    border-radius: 6px;
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.7);
    font-size: 0.85rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.15s ease;
    white-space: nowrap;
}

.webhook-logs__btn:hover:not(:disabled) {
    background: rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.9);
}

.webhook-logs__btn:disabled { opacity: 0.5; cursor: not-allowed; }

.webhook-logs__btn--primary {
    background: var(--c-tertiary-400, #0095d9);
    border-color: var(--c-tertiary-400, #0095d9);
    color: #fff;
}

.webhook-logs__btn--primary:hover:not(:disabled) {
    background: var(--c-tertiary-300, #00a8f0);
}

.webhook-logs__btn--spinning { animation: spin 1s linear infinite; }

@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }

/* ── Mobile Responsive ───────────────────────────────────────────────── */
@media (max-width: 767px) {
    .webhook-logs__header { flex-direction: column; gap: 12px; }
    .webhook-logs__actions { width: 100%; }
    .webhook-logs__btn { width: 100%; justify-content: center; }

    .webhook-log__card-header { flex-direction: column; align-items: flex-start; gap: 10px; }
    .webhook-log__event-info { width: 100%; }
    .webhook-log__actions { width: 100%; justify-content: flex-end; }
    .webhook-log__toggle { flex: 1; justify-content: center; }
    .webhook-log__meta { flex-direction: column; align-items: flex-start; gap: 6px; }

    .webhook-logs__pagination { gap: 2px; }
    .webhook-logs__page-info { width: 100%; text-align: center; margin-left: 0; margin-top: 8px; }
}
</style>
