<template>
    <div id="mountpoint">

        <SiteHeader v-if="$route.meta.showHeader !== false" />
        <main class="wrap">
            <SiteBanner />
            <router-view />
        </main>
    </div>
</template>

<script setup>
    import SiteHeader from './components/site-header.vue'
</script>