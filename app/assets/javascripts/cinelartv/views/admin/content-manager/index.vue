<template>
    <div class="panel content-manager">
        <div class="panel-header">
            <h2 class="panel-title">Gestor de Contenido</h2>
        </div>
        <div class="panel-body">
            <div class="content-manager--nav">
                <div class="content-manager--nav__item" v-for="item in navItems" :key="item.to">
                    <router-link :to="item.to" class="btn btn-primary">
                        {{ item.title }}
                    </router-link>
                </div>
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
const { $t } = getCurrentInstance().appContext.config.globalProperties

const navItems = [
    {
        title: $t("js.admin.content_manager.nav.movies"),
        to: '/admin/content-manager/movies'
    },
    {
        title: $t("js.admin.content_manager.nav.series"),
        to: '/admin/content-manager/series'
    },
    {
        title: $t("js.admin.content_manager.nav.episodes"),
        to: '/admin/content-manager/episodes'
    },
    {
        title: $t("js.admin.content_manager.nav.servers"),
        to: '/admin/content-manager/servers'
    },

]
</script>