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
    </div>
    <div v-else>
      <p>
        Parece que no tienes una suscripción activa.
      </p>
      <button class="mt-4 px-4 py-2 rounded bg-primary text-white disabled:opacity-70" :disabled="isCreatingCheckout"
        @click="createCheckout">
        {{ isCreatingCheckout ? 'Creando checkout...' : 'Suscribirme ahora' }}
      </button>
      <p v-if="checkoutError" class="mt-2 text-sm text-red-500">
        {{ checkoutError }}
      </p>
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
import { ajax } from '../../lib/Ajax';

const billingData = ref(null);
const isCreatingCheckout = ref(false);
const checkoutError = ref('');

const SiteSettings = inject('SiteSettings');
const i18n = inject('I18n');
const currentUser = inject('currentUser');

const fetchBillingData = async () => {
  try {
    const { data } = (await ajax.get('/account/billing.json'));
    return data.data?.[0] || null;
  } catch (error) {
    console.error('Error fetching billing data:', error);
    return null;
  }
};

const createCheckout = async () => {
  isCreatingCheckout.value = true;
  checkoutError.value = '';

  try {
    const { data } = await ajax.post('/account/billing/checkout');
    const checkoutUrl = data?.data?.checkout_url || data?.data?.sandbox_checkout_url;

    if (!checkoutUrl) {
      checkoutError.value = 'No se pudo obtener la URL de checkout.';
      return;
    }

    window.location.href = checkoutUrl;
  } catch (error) {
    console.error('Error creating checkout:', error);
    checkoutError.value = error?.response?.data?.error || 'No se pudo iniciar el checkout.';
  } finally {
    isCreatingCheckout.value = false;
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