<template>
    <div class="admin-plugins">
        <!-- Header -->
        <div class="admin-plugins__header">
            <div class="admin-plugins__header-content">
                <h2 class="admin-plugins__title">
                    <CIcon icon="plug" :size="24" class="admin-plugins__icon" />
                    Plugins
                </h2>
                <p class="admin-plugins__description">
                    Estado de los plugins instalados y su compatibilidad con el núcleo de CinelarTV
                </p>
            </div>
            <div class="admin-plugins__actions">
                <button class="admin-plugins__btn admin-plugins__btn--primary" @click="fetchPlugins" :disabled="loading">
                    <CIcon icon="refresh-cw" :size="18" :class="{ 'admin-plugins__btn--spinning': loading }" />
                    <span>{{ loading ? 'Loading...' : 'Refresh' }}</span>
                </button>
            </div>
        </div>

        <!-- Summary badges -->
        <div v-if="plugins" class="admin-plugins__summary">
            <div class="admin-plugins__summary-item" :class="`admin-plugins__summary-item--${summary.status}`"
                v-for="summary in summaries" :key="summary.status">
                <span class="admin-plugins__summary-count">{{ summary.count }}</span>
                <span class="admin-plugins__summary-label">{{ summary.label }}</span>
            </div>
        </div>

        <!-- Loading state -->
        <div v-if="loading" class="admin-plugins__loading">
            <CIcon icon="loader" :size="32" class="admin-plugins__loading-icon" />
            <p>Loading plugins...</p>
        </div>

        <!-- Empty state -->
        <div v-else-if="plugins && plugins.length === 0" class="admin-plugins__empty">
            <CIcon icon="plug" :size="48" class="admin-plugins__empty-icon" />
            <p class="admin-plugins__empty-title">No plugins found</p>
            <p class="admin-plugins__empty-description">
                Plugins will appear here once they are installed
            </p>
        </div>

        <!-- Plugin list -->
        <div v-else-if="plugins && plugins.length > 0" class="admin-plugins__list">
            <div v-for="plugin in plugins" :key="plugin.id" class="admin-plugin__card"
                :class="{ 'admin-plugin__card--invalid': plugin.status !== 'enabled' }">
                <div class="admin-plugin__card-main">
                    <div class="admin-plugin__identity">
                        <span class="admin-plugin__name">{{ plugin.id }}</span>
                        <span class="admin-plugin__version">v{{ plugin.version }}</span>
                        <span class="admin-plugin__badge" :class="`admin-plugin__badge--${plugin.status}`">
                            {{ plugin.status }}
                        </span>
                    </div>

                    <div class="admin-plugin__reason" v-if="plugin.status !== 'enabled' && plugin.reason">
                        <CIcon icon="alert-triangle" :size="16" />
                        <span>{{ plugin.reason }}</span>
                    </div>

                    <div class="admin-plugin__meta">
                        <span v-if="plugin.has_backend" class="admin-plugin__meta-item">
                            <CIcon icon="server" :size="14" />
                            backend
                        </span>
                        <span v-if="plugin.has_frontend" class="admin-plugin__meta-item">
                            <CIcon icon="layout" :size="14" />
                            frontend
                        </span>
                        <span v-if="plugin.backend_engine" class="admin-plugin__meta-item">
                            <CIcon icon="puzzle" :size="14" />
                            {{ plugin.backend_engine }}
                        </span>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ajax } from '@/lib/Ajax'
import CIcon from '@/components/c-icon.vue'

onMounted(() => {
    fetchPlugins()
})

const plugins = ref(null)
const loading = ref(false)

const fetchPlugins = async () => {
    loading.value = true
    try {
        const response = await ajax.get('/admin/plugins.json')
        plugins.value = response.data.plugins
    } catch (error) {
        console.error('Failed to fetch plugins:', error)
    } finally {
        loading.value = false
    }
}

const summaries = computed(() => {
    if (!plugins.value) return []
    const countByStatus = plugins.value.reduce((acc, plugin) => {
        acc[plugin.status] = (acc[plugin.status] || 0) + 1
        return acc
    }, {})

    const labels = {
        enabled: 'Enabled',
        compatible: 'Compatible',
        blocked: 'Blocked',
        failed: 'Failed',
    }

    return Object.entries(countByStatus).map(([status, count]) => ({
        status,
        count,
        label: labels[status] || status,
    }))
})
</script>

<style scoped>
.admin-plugins {
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
.admin-plugins__header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    gap: 16px;
    margin-bottom: 24px;
    padding-bottom: 20px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.06);
}

.admin-plugins__header-content {
    flex: 1;
}

.admin-plugins__title {
    display: flex;
    align-items: center;
    gap: 12px;
    font-size: 1.25rem;
    font-weight: 600;
    color: #fff;
    margin: 0 0 8px 0;
}

.admin-plugins__icon {
    color: var(--c-tertiary-400, #0095d9);
}

.admin-plugins__description {
    font-size: 0.8rem;
    color: rgba(255, 255, 255, 0.4);
    margin: 0;
}

.admin-plugins__actions {
    display: flex;
    gap: 8px;
}

/* ── Summary ─────────────────────────────────────────────────────────── */
.admin-plugins__summary {
    display: flex;
    gap: 12px;
    margin-bottom: 20px;
    flex-wrap: wrap;
}

.admin-plugins__summary-item {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 10px 16px;
    border-radius: 8px;
    border: 1px solid rgba(255, 255, 255, 0.08);
    background: rgba(255, 255, 255, 0.03);
}

.admin-plugins__summary-count {
    font-size: 1.1rem;
    font-weight: 700;
    color: #fff;
}

.admin-plugins__summary-label {
    font-size: 0.8rem;
    color: rgba(255, 255, 255, 0.6);
    text-transform: capitalize;
}

.admin-plugins__summary-item--blocked .admin-plugins__summary-count,
.admin-plugins__summary-item--failed .admin-plugins__summary-count {
    color: #f87171;
}

/* ── Loading / Empty ─────────────────────────────────────────────────── */
.admin-plugins__loading,
.admin-plugins__empty {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 60px 20px;
    color: rgba(255, 255, 255, 0.5);
    font-size: 0.85rem;
    text-align: center;
}

.admin-plugins__loading-icon {
    animation: spin 1s linear infinite;
    color: var(--c-tertiary-400, #0095d9);
    margin-bottom: 12px;
}

.admin-plugins__empty-icon {
    color: rgba(255, 255, 255, 0.15);
    margin-bottom: 16px;
}

.admin-plugins__empty-title {
    font-size: 1rem;
    font-weight: 500;
    color: rgba(255, 255, 255, 0.6);
    margin: 0 0 6px 0;
}

.admin-plugins__empty-description {
    font-size: 0.8rem;
    color: rgba(255, 255, 255, 0.35);
    margin: 0;
}

/* ── Plugin Cards ────────────────────────────────────────────────────── */
.admin-plugins__list {
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.admin-plugin__card {
    padding: 16px 18px;
    background: rgba(255, 255, 255, 0.03);
    border: 1px solid rgba(255, 255, 255, 0.06);
    border-radius: 8px;
    transition: all 0.15s ease;
}

.admin-plugin__card:hover {
    background: rgba(255, 255, 255, 0.04);
}

.admin-plugin__card--invalid {
    border-color: rgba(248, 113, 113, 0.3);
    background: rgba(248, 113, 113, 0.05);
}

.admin-plugin__identity {
    display: flex;
    align-items: center;
    gap: 10px;
    flex-wrap: wrap;
}

.admin-plugin__name {
    font-size: 0.95rem;
    font-weight: 600;
    color: rgba(255, 255, 255, 0.9);
}

.admin-plugin__version {
    font-size: 0.75rem;
    color: rgba(255, 255, 255, 0.4);
}

.admin-plugin__badge {
    padding: 2px 10px;
    border-radius: 10px;
    font-size: 0.7rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.03em;
}

.admin-plugin__badge--enabled {
    background: rgba(30, 192, 138, 0.15);
    color: #1ec08a;
}

.admin-plugin__badge--compatible {
    background: rgba(0, 168, 240, 0.15);
    color: #00a8f0;
}

.admin-plugin__badge--blocked {
    background: rgba(248, 113, 113, 0.15);
    color: #f87171;
}

.admin-plugin__badge--failed {
    background: rgba(248, 113, 113, 0.15);
    color: #f87171;
}

.admin-plugin__reason {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-top: 10px;
    font-size: 0.8rem;
    color: #fca5a5;
}

.admin-plugin__meta {
    display: flex;
    gap: 16px;
    margin-top: 10px;
    flex-wrap: wrap;
}

.admin-plugin__meta-item {
    display: flex;
    align-items: center;
    gap: 6px;
    font-size: 0.75rem;
    color: rgba(255, 255, 255, 0.45);
}

/* ── Buttons ─────────────────────────────────────────────────────────── */
.admin-plugins__btn {
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

.admin-plugins__btn:hover:not(:disabled) {
    background: rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.9);
}

.admin-plugins__btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
}

.admin-plugins__btn--primary {
    background: var(--c-tertiary-400, #0095d9);
    border-color: var(--c-tertiary-400, #0095d9);
    color: #fff;
}

.admin-plugins__btn--primary:hover:not(:disabled) {
    background: var(--c-tertiary-300, #00a8f0);
}

.admin-plugins__btn--spinning {
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

@media (max-width: 767px) {
    .admin-plugins__header {
        flex-direction: column;
        gap: 12px;
    }

    .admin-plugins__actions {
        width: 100%;
    }

    .admin-plugins__btn {
        width: 100%;
        justify-content: center;
    }
}
</style>
