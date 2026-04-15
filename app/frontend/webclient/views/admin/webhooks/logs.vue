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
                        <span class="webhook-log__event-name">{{ log.event_name }}</span>
                        <span v-if="log.created_at" class="webhook-log__timestamp">
                            <CIcon icon="clock" :size="14" />
                            {{ formatTimestamp(log.created_at) }}
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

                <!-- Expandable payload -->
                <div v-show="expandedIndex === index" class="webhook-log__payload-wrapper">
                    <div class="webhook-log__payload">
                        <pre>{{ formatPayload(log.payload) }}</pre>
                    </div>
                    <button class="webhook-log__copy-btn" @click="copyPayload(log.payload)">
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
    </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ajax } from '../../../lib/Ajax'
import CIcon from '@/components/c-icon.vue'

onMounted(() => {
    fetchLogs()
})

const logs = ref(null)
const loading = ref(false)
const expandedIndex = ref(-1)
const testingWebhook = ref(false)
const testResult = ref(null)

const fetchLogs = async () => {
    loading.value = true
    try {
        const response = await ajax.get('/admin/webhooks/logs.json')
        logs.value = response.data.data
    } catch (error) {
        console.error('Failed to fetch webhook logs:', error)
    } finally {
        loading.value = false
    }
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
        console.log('Payload copied to clipboard')
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
.webhook-logs__header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 16px;
    margin-bottom: 24px;
    padding-bottom: 20px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.06);
}

.webhook-logs__header-content {
    flex: 1;
}

.webhook-logs__title {
    display: flex;
    align-items: center;
    gap: 12px;
    font-size: 1.25rem;
    font-weight: 600;
    color: #fff;
    margin: 0 0 8px 0;
}

.webhook-logs__icon {
    color: var(--c-tertiary-400, #0095d9);
}

.webhook-logs__description {
    font-size: 0.8rem;
    color: rgba(255, 255, 255, 0.4);
    margin: 0;
}

.webhook-logs__actions {
    display: flex;
    gap: 8px;
}

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

.webhook-logs__test-result-icon {
    color: #1ec08a;
}

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

.webhook-log__card:hover {
    background: rgba(255, 255, 255, 0.04);
}

.webhook-log__card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 12px;
}

.webhook-log__event-info {
    display: flex;
    align-items: center;
    gap: 12px;
    flex: 1;
    min-width: 0;
}

.webhook-log__event-name {
    font-size: 0.9rem;
    font-weight: 500;
    color: rgba(255, 255, 255, 0.9);
    padding: 3px 10px;
    border-radius: 10px;
    background: var(--c-tertiary-400, #0095d9);
    color: #fff;
    font-weight: 600;
    white-space: nowrap;
}

.webhook-log__timestamp {
    display: flex;
    align-items: center;
    gap: 6px;
    font-size: 0.75rem;
    color: rgba(255, 255, 255, 0.4);
    white-space: nowrap;
}

.webhook-log__actions {
    display: flex;
    gap: 8px;
    align-items: center;
}

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

.webhook-log__copy-btn {
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

.webhook-log__copy-btn:hover {
    background: rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.9);
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

.webhook-logs__btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
}

.webhook-logs__btn--primary {
    background: var(--c-tertiary-400, #0095d9);
    border-color: var(--c-tertiary-400, #0095d9);
    color: #fff;
}

.webhook-logs__btn--primary:hover:not(:disabled) {
    background: var(--c-tertiary-300, #00a8f0);
}

.webhook-logs__btn--spinning {
    animation: spin 1s linear infinite;
}

@keyframes spin {
    from {
        transform: rotate(0deg);
    }

    to {
        transform: rotate(360deg);
    }
}

/* ── Mobile Responsive ───────────────────────────────────────────────── */
@media (max-width: 767px) {
    .webhook-logs__header {
        flex-direction: column;
        gap: 12px;
    }

    .webhook-logs__actions {
        width: 100%;
    }

    .webhook-logs__btn {
        width: 100%;
        justify-content: center;
    }

    .webhook-log__card-header {
        flex-direction: column;
        align-items: flex-start;
        gap: 10px;
    }

    .webhook-log__event-info {
        width: 100%;
        flex-direction: column;
        align-items: flex-start;
        gap: 8px;
    }

    .webhook-log__actions {
        width: 100%;
        justify-content: flex-end;
    }

    .webhook-log__toggle {
        flex: 1;
        justify-content: center;
    }
}
</style>
