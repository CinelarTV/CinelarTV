<template>
    <div class="panel content-manager">
        <div class="panel-body">
            <div class="admin-main-nav content-manager-nav">
                <ul class="nav nav-pills overflow-x-auto">
                    <li v-for="item in navItems" :key="item.to">
                        <router-link class="nav-item min-w-0 whitespace-nowrap" :to="item.to"
                            active-class="admin-nav-active">
                            <component :is="item.icon" :size="18" class="icon"></component>
                            {{ item.title }}
                        </router-link>
                    </li>
                </ul>
            </div>
            <router-view />
        </div>
    </div>
</template>

<script setup>
import { ref, inject } from 'vue'
import { useRoute } from 'vue-router'
import { useHead } from 'unhead'
import { getCurrentInstance } from 'vue'
import { ClapperboardIcon, TvIcon, ShapesIcon, ActivityIcon } from 'lucide-vue-next'

const SiteSettings = inject('SiteSettings')
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

.content-manager-nav .nav-item {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 8px 14px;
    font-size: 0.85rem;
}

.content-manager-nav .nav-item .icon {
    flex-shrink: 0;
}
</style>