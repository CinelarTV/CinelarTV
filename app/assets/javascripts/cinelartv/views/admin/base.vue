<template>
    <div class="admin-dashboard wrap">
      <div class="admin-main-nav">
        <ul class="nav nav-pills overflow-x-auto">
          <li v-for="link in adminLinks" :key="link.to">
            <router-link class="nav-item min-w-0 whitespace-nowrap" :to="link.to" active-class="admin-nav-active" :v-if="link.enabled === true">
              {{ link.title }}
            </router-link>
          </li>
        </ul>
      </div>
      <router-view></router-view>
    </div>
  </template>
  
  <script setup>
import { useMeta } from 'vue-meta'
import { ref, getCurrentInstance } from 'vue'
import { SiteSettings } from '../../pre-initializers/essentials-preload'
const { $t } = getCurrentInstance().appContext.config.globalProperties


const adminLinks = [
  {
    title: $t("js.admin.nav.dashboard"),
    to: '/admin/dashboard'
  },
  {
    title: $t("js.admin.nav.content"),
    to: '/admin/content'
  },
  {
    title: $t("js.admin.nav.users"),
    to: '/admin/users'
  },
  {
    title: $t("js.admin.nav.settings"),
    to: '/admin/settings'
  },
  {
    title: $t("js.admin.nav.updater"),
    to: '/admin/updates',
    enabled: SiteSettings.enable_web_updater || false
  }
].filter(link => link.enabled !== false)

useMeta({
  title: 'Admin'
})
</script>
