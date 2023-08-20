<template>
    <header id="site-header">
        <div class="site-header-wrap">
            <div class="title">
                <router-link to="/">
                    <img id="site-logo" :src="SiteSettings.site_logo" :alt="`${SiteSettings.site_name} logo`" />
                </router-link>
            </div>
            <div class="site-navigation--nav hidden-sm-and-down" role="navigation">
                <template v-for="i in headerItems" :key="i.to">
                    <router-link class="flex site-nav--btn" :to="i.to" v-if="i.showItem">
                        <component :is="i.icon" :size="20" class="icon"></component>
                        {{ i.title }}
                    </router-link>
                </template>
            </div>
            <div class="header-user-panel--nav">
                <div icon class="mr-2 btn-icon" v-if="currentUser">
                    <MessageCircle :size="24" />
                </div>
                <UserMenu />
                <LoginModal ref="loginModal" />
            </div>
        </div>
    </header>
</template>
  
<script setup>
import { ref } from 'vue'
import LoginModal from '../components/modals/login.modal.vue'
import { SiteSettings, currentUser } from '../pre-initializers/essentials-preload';
import UserMenu from '../components/user-menu.vue'
import {
    CompassIcon as ExploreIcon,
    SearchIcon,
    BookmarkIcon,
    ShuffleIcon,
} from 'lucide-vue-next'

const loginModal = ref(null)

const headerItems = ref([
    {
        to: '/',
        title: 'Explorar',
        icon: ExploreIcon,
        showItem: true
    },
    {
        to: '/search',
        title: 'Buscar',
        icon: SearchIcon,
        showItem: true
    },
    {
        to: '/collections',
        title: 'Mi Colección',
        icon: BookmarkIcon,
        showItem: true
    }
])
</script>