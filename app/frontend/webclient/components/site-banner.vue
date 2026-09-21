<template>

    <div v-if="visibleBanners.length && $route.meta.showHeader !== false" id="global-alerts"
        class="global-alerts-wrapper" role="region" aria-label="Alertas del sitio">
        <TransitionGroup name="banner" tag="div">
            <template v-for="banner in visibleBanners" :key="banner.id">

                <!-- Custom HTML banner -->
                <div v-if="banner.customHtml" :id="banner.id" class="global-banner-item" v-html="banner.customHtml" />

                <!-- Standard banner -->
                <div v-else :id="banner.id"
                    :class="['global-notice', banner.type ? `global-notice--${banner.type}` : 'global-notice--default']"
                    role="alert" aria-live="polite">
                    <!-- Icon -->
                    <span class="global-notice__icon" aria-hidden="true">
                        <component :is="iconFor(banner.type)" />
                    </span>

                    <!-- Content -->
                    <span class="global-notice__body" v-html="renderContent(banner.content)" @click="onBannerClick" />

                    <!-- Dismiss button -->
                    <button v-if="banner.dismissible !== false" class="global-notice__dismiss"
                        :aria-label="`Cerrar: ${banner.id}`" @click="removeBanner(banner.id)">
                        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none"
                            stroke="currentColor" stroke-width="2.5" stroke-linecap="round">
                            <line x1="18" y1="6" x2="6" y2="18" />
                            <line x1="6" y1="6" x2="18" y2="18" />
                        </svg>
                    </button>
                </div>

            </template>
        </TransitionGroup>
    </div>

</template>

<script setup lang="ts">
import { computed, defineComponent, h, onMounted, getCurrentInstance } from 'vue'
import { storeToRefs } from 'pinia'
import { useBanners } from '../app/services/banner-store'
import { useSiteSettings } from '../app/services/site-settings';
import { useCurrentUser } from '../app/services/current-user'
import { ajax } from '../lib/Ajax'
import { toast } from 'vue-sonner'

// Store
const bannerStore = useBanners()
const { addBanner, removeBanner } = bannerStore
const { banners } = storeToRefs(bannerStore)

// App services
const { siteSettings } = useSiteSettings()
const { currentUser } = useCurrentUser()
const { $t } = getCurrentInstance()?.appContext.config.globalProperties ?? {}

// Computed
const visibleBanners = computed(() =>
    banners.value?.filter((b) => b?.show) ?? []
)

// Markdown-link → anchor (also handles action: protocol for JS handlers)
const renderContent = (content: string): string => {
    if (!content) return ''
    return content.replace(
        /\[([^\]]+)\]\(([^)]+)\)/g,
        '<a href="$2" target="_blank" rel="noopener noreferrer">$1</a>'
    )
}

// Handle clicks on banner links — intercept action: protocol
const onBannerClick = async (e: Event) => {
    const target = e.target as HTMLElement
    if (target.tagName !== 'A') return
    const href = target.getAttribute('href')
    if (!href?.startsWith('action:')) return

    e.preventDefault()
    const action = href.replace('action:', '')

    if (action === 'resend-confirmation') {
        await resendConfirmationEmail()
    }
}

const resendConfirmationEmail = async () => {
    if (!currentUser?.email) return
    try {
        await ajax.post('/confirmation.json', {
            user: { email: currentUser.email },
        })
        toast.success('Correo de confirmación reenviado. Revisa tu bandeja de entrada.')
    } catch {
        toast.error('Error al reenviar el correo. Intenta de nuevo más tarde.')
    }
}

// Icon per type — inline SVG components
const ICONS: Record<string, ReturnType<typeof defineComponent>> = {
    info: defineComponent(() => () =>
        h('svg', { xmlns: 'http://www.w3.org/2000/svg', width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': 2, 'stroke-linecap': 'round', 'stroke-linejoin': 'round' }, [
            h('circle', { cx: 12, cy: 12, r: 10 }),
            h('line', { x1: 12, y1: 8, x2: 12, y2: 12 }),
            h('line', { x1: 12, y1: 16, x2: '12.01', y2: 16 }),
        ])
    ),
    warning: defineComponent(() => () =>
        h('svg', { xmlns: 'http://www.w3.org/2000/svg', width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': 2, 'stroke-linecap': 'round', 'stroke-linejoin': 'round' }, [
            h('path', { d: 'M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z' }),
            h('line', { x1: 12, y1: 9, x2: 12, y2: 13 }),
            h('line', { x1: 12, y1: 17, x2: '12.01', y2: 17 }),
        ])
    ),
    danger: defineComponent(() => () =>
        h('svg', { xmlns: 'http://www.w3.org/2000/svg', width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': 2, 'stroke-linecap': 'round', 'stroke-linejoin': 'round' }, [
            h('circle', { cx: 12, cy: 12, r: 10 }),
            h('line', { x1: 15, y1: 9, x2: 9, y2: 15 }),
            h('line', { x1: 9, y1: 9, x2: 15, y2: 15 }),
        ])
    ),
    success: defineComponent(() => () =>
        h('svg', { xmlns: 'http://www.w3.org/2000/svg', width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': 2, 'stroke-linecap': 'round', 'stroke-linejoin': 'round' }, [
            h('path', { d: 'M22 11.08V12a10 10 0 1 1-5.93-9.14' }),
            h('polyline', { points: '22 4 12 14.01 9 11.01' }),
        ])
    ),
    default: defineComponent(() => () =>
        h('svg', { xmlns: 'http://www.w3.org/2000/svg', width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none', stroke: 'currentColor', 'stroke-width': 2, 'stroke-linecap': 'round', 'stroke-linejoin': 'round' }, [
            h('circle', { cx: 12, cy: 12, r: 10 }),
            h('line', { x1: 12, y1: 8, x2: 12, y2: 12 }),
            h('line', { x1: 12, y1: 16, x2: '12.01', y2: 16 }),
        ])
    ),
}

const iconFor = (type?: string) => ICONS[type ?? 'default'] ?? ICONS.default

// Bootstrap banners on mount
onMounted(() => {
    addBanner({
        id: 'site-unconfigured',
        type: 'warning',
        dismissible: false,
        content: `${$t?.('js.admin.wizard_required') ?? 'Wizard required'} [${$t?.('js.admin.wizard_link') ?? 'Configure'}](/wizard)`,
        show: Boolean(!siteSettings?.wizard_completed && currentUser?.admin),
    })

    // Email confirmation banner
    if (currentUser && !currentUser.confirmed && currentUser.confirmation_deadline) {
        const deadline = new Date(currentUser.confirmation_deadline)
        const daysLeft = Math.ceil((deadline.getTime() - Date.now()) / (1000 * 60 * 60 * 24))
        const type = daysLeft <= 2 ? 'danger' : 'warning'
        const dayText = daysLeft === 1 ? 'queda 1 día' : `quedan ${daysLeft} días`

        addBanner({
            id: 'email-confirmation',
            type,
            dismissible: true,
            content: `Verifica tu correo electrónico. Te ${dayText} para confirmar tu cuenta. [Reenviar email](action:resend-confirmation)`,
            show: true,
        })
    }
})
</script>

<style scoped>
@reference "../styles/cinelartv.css";

.global-alerts-wrapper {
    @apply w-full;
}

.global-notice {
    display: flex;
    align-items: flex-start;
    gap: 10px;
    max-width: 1150px;
    margin: 0 auto;
    padding: 12px 16px;
    border-left: 3px solid transparent;
    border-radius: var(--c-radius-sm);
    font-size: 13px;
    line-height: 1.55;
    animation: banner-in 0.25s ease-out both;
}

.global-notice--info {
    background: var(--c-surface-2);
    border-color: var(--c-tertiary-color);
    color: var(--c-tertiary-300);
}

.global-notice--warning {
    background: var(--c-surface-2);
    border-color: var(--c-warning);
    color: var(--c-warning);
}

.global-notice--danger {
    background: var(--c-surface-2);
    border-color: var(--c-danger);
    color: var(--c-danger);
}

.global-notice--success {
    background: var(--c-surface-2);
    border-color: var(--c-success);
    color: var(--c-success);
}

.global-notice--default {
    background: var(--c-surface-2);
    border-color: var(--c-border-strong);
    color: var(--c-text-primary);
}

.global-notice__icon {
    flex-shrink: 0;
    margin-top: 1px;
    opacity: 0.9;
}

.global-notice__body {
    flex: 1;
    min-width: 0;
}

.global-notice__body :deep(a) {
    text-decoration: underline;
    color: inherit;
    opacity: 0.85;
    transition: opacity 0.15s;
}

.global-notice__body :deep(a:hover) {
    opacity: 1;
}

.global-notice__dismiss {
    flex-shrink: 0;
    background: none;
    border: none;
    cursor: pointer;
    padding: 2px;
    border-radius: var(--c-radius-sm);
    color: inherit;
    opacity: 0.4;
    line-height: 1;
    transition: opacity 0.15s, background 0.15s;
}

.global-notice__dismiss:hover {
    opacity: 1;
    background: var(--c-surface-3);
}

.banner-enter-active {
    animation: banner-in 0.25s ease-out;
}

.banner-leave-active {
    animation: banner-out 0.2s ease-in forwards;
}

@keyframes banner-in {
    from {
        opacity: 0;
        transform: translateY(-6px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
}

@keyframes banner-out {
    from {
        opacity: 1;
        max-height: 80px;
    }
    to {
        opacity: 0;
        max-height: 0;
        padding-top: 0;
        padding-bottom: 0;
    }
}
</style>