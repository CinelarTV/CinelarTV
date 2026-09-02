<template>
    <div class="panel content-manager">
        <div class="panel-body">
            <div class="admin-nav content-manager-nav">
                <div class="admin-nav__scroll">
                    <router-link
                        v-for="item in navItems"
                        :key="item.to"
                        class="admin-nav__item"
                        :to="item.to"
                        active-class="admin-nav__item--active"
                    >
                        <component :is="item.icon" :size="16" class="admin-nav__icon" />
                        <span class="admin-nav__label">{{ item.title }}</span>
                    </router-link>
                </div>
            </div>
            <router-view />
        </div>
    </div>
</template>

<script setup>
import { inject, getCurrentInstance } from 'vue'
import { useHead } from 'unhead'
import { ClapperboardIcon, TvIcon, ShapesIcon, ActivityIcon } from 'lucide-vue-next'

const { $t } = getCurrentInstance().appContext.config.globalProperties

const navItems = [
    {
        icon: ClapperboardIcon,
        title: $t("js.admin.content_manager.nav.all_content"),
        to: '/admin/content-manager/all'
    },
    {
        icon: TvIcon,
        title: $t("js.admin.content_manager.nav.series"),
        to: '/admin/content-manager/series'
    },
    {
        icon: ShapesIcon,
        title: $t("js.admin.content_manager.nav.categories"),
        to: '/admin/content-manager/categories'
    },
    {
        icon: ActivityIcon,
        title: $t("js.admin.content_manager.nav.media_integrity"),
        to: '/admin/content-manager/media-integrity'
    }
]

useHead({
    title: $t("js.admin.content_manager.title")
})
</script>

<style scoped>
.content-manager-nav {
    margin-bottom: 16px;
}
</style>
