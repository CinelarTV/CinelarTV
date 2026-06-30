<template>
  <div class="admin-dashboard wrap">
    <div class="admin-main-nav">
      <ul class="nav nav-pills overflow-x-auto">
        <li v-for="link in adminLinks" :key="link.to">
          <router-link class="nav-item min-w-0 whitespace-nowrap" :to="link.to" active-class="admin-nav-active"
            v-if="link.enabled !== false">
            <CIcon v-if="link.icon" :icon="link.icon" class="icon" />
            {{ link.title }}
          </router-link>
        </li>
      </ul>
    </div>
    <router-view></router-view>
  </div>
</template>

<script setup>
import CIcon from "@/components/c-icon.vue"
import { useHead } from 'unhead'
import { ref, getCurrentInstance, inject } from 'vue'
const SiteSettings = inject('SiteSettings')
const { $t } = getCurrentInstance().appContext.config.globalProperties


const adminLinks = [
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
    to: '/admin/content-manager'
  },
  {
    title: $t("js.admin.nav.users"),
    to: '/admin/users'
  },
  {
    title: $t("js.admin.nav.subscriptions") || 'Subscriptions',
    to: '/admin/subscriptions',
    enabled: SiteSettings.enable_subscription || false
  },
  {
    title: $t("js.admin.nav.live_tv") || 'Live TV',
    icon: 'satellite-dish',
    to: '/admin/live-tv',
    enabled: SiteSettings.enable_live_tv || false // Only show if Live TV is enabled
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
    to: '/admin/webhooks/logs',
    enabled: SiteSettings.enable_subscription || false // Webhooks are only available if subscriptions are enabled
  },
  {
    title: $t("js.admin.nav.updater"),
    icon: 'package-open',
    to: '/admin/updates',
    enabled: SiteSettings.enable_web_updater || false
  },
].filter(link => link.enabled !== false)

useHead({
  title: 'Admin'
})
</script>
