<template>
    <div class="px-4" v-if="SiteSettings.enable_subscription">
      <div class="flex mb-4 items-center">
        <c-icon icon="credit-card" :size="24" />
        <h2 class="text-2xl font-medium ml-2">
          Administrar suscripción
        </h2>
      </div>
  
      <div v-if="billingData">
        <p>
          <strong>Nombre del producto:</strong> {{ billingData.product_name }}
        </p>
        <p>
          <strong>Variante:</strong> {{ billingData.variant_name }}
        </p>
        <p>
          <strong>Estado:</strong> {{ billingData.status_formatted }}
        </p>
        <p>
          <strong>Fecha de finalización de la prueba:</strong> {{ billingData.trial_ends_at }}
        </p>
        <!-- Agrega más detalles de la suscripción según sea necesario -->
      </div>
    </div>
    <div v-else>
      <div class="flex mb-4 items-center">
        <c-icon icon="credit-card" :size="24" />
        <h2 class="text-2xl font-medium ml-2">
          Suscripciones deshabilitadas
        </h2>
      </div>
      <p>
        Las suscripciones están deshabilitadas en este momento.
      </p>
    </div>
  </template>
  
  <script setup>
  import { ref, onMounted, inject } from 'vue';
  import { useHead } from 'unhead';
  import { ajax } from '../../lib/axios-setup';
  
  const billingData = ref(null);
  
  const SiteSettings = inject('SiteSettings');
  const i18n = inject('I18n');
  const currentUser = inject('currentUser');
  
  const fetchBillingData = async () => {
    try {
      const { data } = (await ajax.get('/account/billing.json'));
      return data.data[0]; // Suponiendo que siempre tienes un solo elemento en el array
    } catch (error) {
      console.error('Error fetching billing data:', error);
      return null;
    }
  };
  
  onMounted(async () => {
    billingData.value = await fetchBillingData();
  });
  
  useHead({
    title: 'Administrar suscripción',
    meta: [
      {
        name: 'description',
        content: 'Administrar suscripción',
      },
    ],
  });
  </script>
  