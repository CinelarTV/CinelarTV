<template>
    <div class="panel content-manager">
        <div class="panel-body">
            <div class="admin-main-nav">
                <ul class="nav nav-pills overflow-x-auto">
                    <li v-for="item in navItems" :key="item.to">
                        <router-link class="nav-item min-w-0 whitespace-nowrap" :to="item.to" active-class="admin-nav-active">
                            <component :is="item.icon" :size="20" class="icon"></component>
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
import { ref } from 'vue'
import { useRoute } from 'vue-router'
import { useMeta } from 'vue-meta'
import { getCurrentInstance } from 'vue'
import { SiteSettings } from '../../../pre-initializers/essentials-preload'
import { ClapperboardIcon, TvIcon } from 'lucide-vue-next'
import { ShapesIcon } from 'lucide-vue-next'
import { RouterIcon } from 'lucide-vue-next'
const { $t } = getCurrentInstance().appContext.config.globalProperties

const navItems = [
    {
        icon: ClapperboardIcon,
        title: $t("js.admin.content_manager.nav.all_content"),
        to: '/admin/content-manager/all'
    },
    {
        icon: ShapesIcon,
        title: $t("js.admin.content_manager.nav.categories"),
        to: '/admin/content-manager/categories'
    }

]
</script>