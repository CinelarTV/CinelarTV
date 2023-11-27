<template>
    <header id="site-header">
        <div class="site-header-wrap">
            <div class="title">
                <router-link to="/">
                    <img id="site-logo" :src="siteSettings.site_logo" :alt="`${siteSettings.site_name} logo`" />
                </router-link>
            </div>
            <div class="site-navigation--nav hidden-sm-and-down" role="navigation">
                <router-link v-for="item in filteredHeaderItems" :key="item.to" class="flex site-nav--btn" :to="item.to">
                    <component :is="item.icon" :size="20" class="icon"></component>
                    {{ item.title }}
                </router-link>
            </div>
            <div class="header-user-panel--nav">
                <UserMenu />
                <LoginModal />
            </div>
        </div>
    </header>
</template>
  
<script setup>
import { useSiteSettings } from '../app/services/site-settings';
import LoginModal from '../components/modals/login.modal.vue';
import UserMenu from '../app/components/header/user-menu.vue';
import { CompassIcon as ExploreIcon, SearchIcon, BookmarkIcon } from 'lucide-vue-next';
const { siteSettings } = useSiteSettings();


const headerItems = [
    { to: '/', title: 'Explorar', icon: ExploreIcon, showItem: true },
    { to: '/search', title: 'Buscar', icon: SearchIcon, showItem: true },
    { to: '/collections', title: 'Mi Colección', icon: BookmarkIcon, showItem: true },
];

const filteredHeaderItems = headerItems.filter(item => item.showItem);
</script>
  