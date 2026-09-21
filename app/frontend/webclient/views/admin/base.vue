<template>
  <div class="admin-dashboard wrap">
    <div class="admin-nav">
      <div class="admin-nav__scroll">
        <router-link
          v-for="link in adminLinks"
          :key="typeof link.to === 'string' ? link.to : link.to?.name || JSON.stringify(link.to)"
          class="admin-nav__item"
          :to="link.to"
          active-class="admin-nav__item--active"
        >
          <CIcon v-if="link.icon" :icon="link.icon" :size="16" class="admin-nav__icon" />
          <span class="admin-nav__label">{{ link.title }}</span>
        </router-link>
        <span class="admin-nav__indicator" ref="indicatorRef" />
      </div>
    </div>
    <router-view />
  </div>
</template>

<script setup>
import CIcon from "@/components/c-icon.vue"
import { useHead } from 'unhead'
import { ref, inject, nextTick, onMounted, onUpdated, getCurrentInstance, computed } from 'vue'
import { useRoute } from 'vue-router'
import { getPluginAdminTabs } from "@/plugins/AdminNavStore"

const SiteSettings = inject('SiteSettings')
const { $t } = getCurrentInstance().appContext.config.globalProperties
const route = useRoute()
const indicatorRef = ref(null)

const updateIndicator = () => {
  nextTick(() => {
    const nav = document.querySelector('.admin-nav__scroll')
    const active = nav?.querySelector('.admin-nav__item--active')
    const indicator = indicatorRef.value
    if (!nav || !active || !indicator) return

    const navRect = nav.getBoundingClientRect()
    const tabRect = active.getBoundingClientRect()

    indicator.style.left = `${tabRect.left - navRect.left + nav.scrollLeft}px`
    indicator.style.width = `${tabRect.width}px`
  })
}

onMounted(updateIndicator)
onUpdated(updateIndicator)

const adminLinks = computed(() => {
  const core = [
    {
      title: $t("js.admin.nav.dashboard"),
      icon: 'home',
      to: '/admin/dashboard'
    },
    {
      title: $t("js.admin.nav.settings"),
      icon: 'settings',
      to: '/admin/settings'
    },
    {
      title: $t("js.admin.nav.content"),
      icon: 'clapperboard',
      to: '/admin/content-manager'
    },
    {
      title: $t("js.admin.nav.users"),
      icon: 'users',
      to: '/admin/users'
    },
    {
      title: $t("js.admin.nav.subscriptions") || 'Subscriptions',
      icon: 'credit-card',
      to: '/admin/subscriptions',
      enabled: SiteSettings.enable_subscription || false
    },
    {
      title: $t("js.admin.nav.live_tv") || 'Live TV',
      icon: 'satellite-dish',
      to: '/admin/live-tv',
      enabled: SiteSettings.enable_live_tv || false
    },
    {
      title: $t("js.admin.nav.email_templates") || 'Email Templates',
      icon: 'mail',
      to: '/admin/email-templates'
    },
    {
      title: $t("js.admin.nav.email_style") || 'Email Style',
      icon: 'palette',
      to: '/admin/customize/email-style'
    },
    {
      title: 'Webhooks',
      icon: 'webhook',
      to: '/admin/webhooks/logs',
      enabled: SiteSettings.enable_subscription || false
    },
    {
      title: $t("js.admin.nav.backups") || 'Backups',
      icon: 'database',
      to: '/admin/backups'
    },
    {
      title: $t("js.admin.nav.plugins") || 'Plugins',
      icon: 'plug',
      to: '/admin/plugins'
    },
    {
      title: $t("js.admin.nav.updater"),
      icon: 'package-open',
      to: '/admin/updates',
      enabled: SiteSettings.enable_web_updater || false
    },
  ].filter(link => link.enabled !== false);

  const pluginTabs = getPluginAdminTabs().map(tab => ({
    title: tab.label,
    icon: tab.icon,
    to: tab.route ? { name: tab.route } : tab.path,
    plugin: tab.pluginId,
  }));

  return [...core, ...pluginTabs];
})

useHead({
  title: 'Admin'
})
</script>
