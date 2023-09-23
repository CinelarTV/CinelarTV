<template>
    <div class="px-4">
        <div class="flex mb-4 items-center">
            <c-icon icon="credit-card" :size="24" />
            <h2 class="text-2xl font-medium ml-2">
                Administrar suscripción
            </h2>
        </div>


        <div>
            {{ billingData }}
        </div>
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
    const { data } = await ajax.get('/account/billing.json');
    return data.data
};

onMounted(async () => {
    billingData.value = await fetchBillingData()
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