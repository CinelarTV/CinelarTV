<script setup lang="ts">
import { useSiteSettings } from "@/app/services/site-settings";
import CIcon from "@/components/c-icon.vue";

const { siteSettings } = useSiteSettings();

</script>

<template>
    <div>
        <div class="bg-blue-500 text-white p-4 rounded-lg mb-4">
            Introducing Watch Party
        </div>
        <CIcon icon="airplay" />

        <span class="text-white">
            Ruta actual {{ $route.path }}
            {{ siteSettings.cinelar_watchparty_enabled ? 'Watch Party is enabled' : 'Watch Party is disabled' }}
        </span>

        <div class="mt-4 text-red-500">
            Esta ruta fue cargada desde el plugin <strong>cinelar-watchparty</strong> de forma dinámica
        </div>
    </div>
</template>