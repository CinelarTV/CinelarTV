<template>
  <div class="admin-dashboard wrap">
    <div class="admin-main-nav">
      <ul class="nav nav-pills overflow-x-auto">
        <li v-for="link in adminLinks" :key="link.to">
          <router-link class="nav-item min-w-0 whitespace-nowrap" :to="link.to" active-class="admin-nav-active"
            :v-if="link.enabled === true">
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
    title: $t("js.admin.nav.content"),
    to: '/admin/content-manager'
  },
  {
    title: $t("js.admin.nav.users"),
    to: '/admin/users'
  },
  {
    title: $t("js.admin.nav.settings"),
    icon: 'settings',
    to: '/admin/settings'
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
  {
    title: "Webhooks",
    icon: 'webhook',
    to: '/admin/webhooks/logs'
  }
].filter(link => link.enabled !== false)

useHead({
  title: 'Admin'
})
</script>
