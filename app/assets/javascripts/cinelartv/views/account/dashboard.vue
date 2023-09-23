<template>
    <div class="px-4">
      <div class="flex mb-4 items-center">
        <c-icon icon="layout-grid" :size="24" />
        <h2 class="text-2xl font-medium ml-2">
            Bienvenido a tu cuenta
        </h2>
      </div>
  
    </div>
  </template>
  
  <script setup>
  import { ref, onMounted, inject } from 'vue';
  import { useHead } from 'unhead';
  import { ajax } from '../../lib/axios-setup';
    
  const SiteSettings = inject('SiteSettings');
  const i18n = inject('I18n');
  const currentUser = inject('currentUser');
  
  
  onMounted(async () => {
    billingData.value = await fetchBillingData();
  });
  
  useHead({
    title: `Mi ${SiteSettings.site_name}`,
    meta: [
      {
        name: 'description',
        content: 'Mi cuenta',
      },
    ],
  });
  </script>
  