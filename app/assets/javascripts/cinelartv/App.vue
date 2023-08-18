<template>
    <div id="mountpoint">

        <SiteHeader />
        <main class="wrap">
            <SiteBanner />
            <router-view />
        </main>
    </div>
</template>

<script setup>
    import SiteHeader from './components/site-header.vue'
</script>