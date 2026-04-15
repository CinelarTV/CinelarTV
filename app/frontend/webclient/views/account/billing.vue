<template>
  <div class="billing-page">
    <!-- Header -->
    <div class="billing-page__header">
      <div class="billing-page__header-content">
        <h1 class="billing-page__title">
          <CIcon icon="credit-card" :size="28" class="billing-page__icon" />
          Subscription Management
        </h1>
        <p class="billing-page__description">
          Manage your subscription plan and billing details
        </p>
      </div>
    </div>

    <!-- Subscriptions disabled -->
    <div v-if="!SiteSettings.enable_subscription" class="billing-page__disabled">
      <CIcon icon="credit-card-off" :size="48" class="billing-page__disabled-icon" />
      <h2 class="billing-page__disabled-title">Subscriptions Disabled</h2>
      <p class="billing-page__disabled-description">
        Subscriptions are currently disabled by the site administrator.
      </p>
    </div>

    <!-- Initial loading -->
    <div v-else-if="isHydratingBilling" class="billing-page__loading-state">
      <div class="billing-page__loading-icon-wrap">
        <CIcon icon="loader" :size="24" class="billing-page__loading-icon" />
      </div>
      <h2 class="billing-page__loading-title">Loading your membership</h2>
      <p class="billing-page__loading-description">
        We are syncing your subscription status with the payment provider.
      </p>
    </div>

    <!-- Active subscription -->
    <div v-else-if="subscription" class="billing-page__content">
      <!-- Status Card -->
      <div class="billing-page__card" :class="`billing-page__card--${subscriptionStatusClass}`">
        <div class="billing-page__status-header">
          <div class="billing-page__status-icon">
            <CIcon :icon="subscriptionStatusIcon" :size="32" />
          </div>
          <div class="billing-page__status-info">
            <h2 class="billing-page__status-title">
              {{ subscription.product_name || 'Subscription Plan' }}
            </h2>
            <p class="billing-page__status-plan">
              {{ subscription.variant_name || 'Monthly Plan' }}
            </p>
          </div>
        </div>
        <div class="billing-page__status-badge" :class="`billing-page__status-badge--${subscriptionStatusClass}`">
          <CIcon :icon="subscriptionStatusBadgeIcon" :size="16" />
          <span>{{ subscription.status_formatted || subscription.status }}</span>
        </div>
      </div>

      <!-- Subscription Details -->
      <div class="billing-page__details">
        <h3 class="billing-page__section-title">
          <CIcon icon="info" :size="20" />
          Subscription Details
        </h3>
        <div class="billing-page__details-grid">
          <div class="billing-page__detail-card">
            <div class="billing-page__detail-icon">
              <CIcon icon="calendar" :size="20" />
            </div>
            <span class="billing-page__detail-label">Next Billing Date</span>
            <span class="billing-page__detail-value">
              {{ formatDate(subscription.renews_at) }}
            </span>
          </div>
          <div class="billing-page__detail-card">
            <div class="billing-page__detail-icon">
              <CIcon icon="credit-card" :size="20" />
            </div>
            <span class="billing-page__detail-label">Provider</span>
            <span class="billing-page__detail-value">
              {{ formatProvider(subscription.provider) }}
            </span>
          </div>
          <div class="billing-page__detail-card">
            <div class="billing-page__detail-icon">
              <CIcon icon="mail" :size="20" />
            </div>
            <span class="billing-page__detail-label">Account Email</span>
            <span class="billing-page__detail-value">
              {{ subscription.user_email || currentUser?.email || 'N/A' }}
            </span>
          </div>
          <div class="billing-page__detail-card" v-if="subscription.trial_ends_at">
            <div class="billing-page__detail-icon">
              <CIcon icon="gift" :size="20" />
            </div>
            <span class="billing-page__detail-label">Trial Ends</span>
            <span class="billing-page__detail-value">
              {{ formatDate(subscription.trial_ends_at) }}
            </span>
          </div>
        </div>
      </div>

      <!-- Actions -->
      <div class="billing-page__actions">
        <BillingActionButton icon="external-link" @click="manageSubscription">
          Manage Subscription
        </BillingActionButton>
        <BillingActionButton v-if="canCancel" icon="x-circle" variant="danger" @click="cancelSubscription">
          Cancel Subscription
        </BillingActionButton>
      </div>
    </div>

    <!-- Awaiting activation -->
    <div v-else-if="isAwaitingActivation" class="billing-page__pending">
      <div class="billing-page__pending-card">
        <div class="billing-page__pending-pulse" />
        <h2 class="billing-page__pending-title">Finalizing your subscription</h2>
        <p class="billing-page__pending-description">
          Your payment was received. We are waiting for confirmation from {{ providerProfile.displayName }}.
        </p>
        <BillingActionButton icon="refresh-cw" :loading="isHydratingBilling" @click="refreshBillingStatus">
          Refresh status
        </BillingActionButton>
      </div>
    </div>

    <!-- No subscription -->
    <div v-else class="billing-page__subscribe">
      <div class="billing-page__subscribe-card">
        <div class="billing-page__subscribe-hero">
          <CIcon icon="sparkles" :size="26" class="billing-page__subscribe-hero-icon" />
          <span class="billing-page__subscribe-hero-kicker">CinelarTV Premium</span>
        </div>

        <h2 class="billing-page__subscribe-title">Start your streaming membership</h2>
        <p class="billing-page__subscribe-description">
          {{ providerProfile.subscribeDescription }}
        </p>

        <ul class="billing-page__benefits">
          <li class="billing-page__benefit-item">
            <CIcon icon="check-circle" :size="16" class="billing-page__benefit-icon" />
            Unlimited access to your catalog
          </li>
          <li class="billing-page__benefit-item">
            <CIcon icon="check-circle" :size="16" class="billing-page__benefit-icon" />
            Continue watching across devices
          </li>
          <li class="billing-page__benefit-item">
            <CIcon icon="check-circle" :size="16" class="billing-page__benefit-icon" />
            Faster support for billing issues
          </li>
        </ul>

        <div class="billing-page__secure-badge" v-if="providerProfile.supportsInlineCardForm && showInlineCardForm">
          <CIcon icon="shield-check" :size="16" />
          {{ providerProfile.secureBadgeText }}
        </div>

        <BillingActionButton large icon="external-link" loading-icon="loader" :loading="isCreatingCheckout"
          :disabled="isCreatingCheckout" @click="createSubscription">
          {{ isCreatingCheckout ? providerProfile.checkoutLoadingCta : providerProfile.checkoutCta }}
        </BillingActionButton>

        <BillingActionButton v-if="providerProfile.supportsWalletCheckout"
          icon="dollar-sign" loading-icon="loader" :loading="isCreatingCheckout" :disabled="isCreatingCheckout"
          @click="createSubscription('wallet_balance')">
          {{ isCreatingCheckout ? providerProfile.walletLoadingCta : providerProfile.walletCta }}
        </BillingActionButton>

        <BillingActionButton v-if="providerProfile.supportsInlineCardForm && !showInlineCardForm"
          icon="credit-card" @click="openInlineCardForm">
          Pay with card here
        </BillingActionButton>

        <BillingActionButton v-if="providerProfile.supportsInlineCardForm && showInlineCardForm"
          icon="chevron-up" @click="closeInlineCardForm">
          Hide card form
        </BillingActionButton>

        <form v-if="providerProfile.supportsInlineCardForm && showInlineCardForm" class="billing-page__form"
          @submit.prevent="createSubscriptionWithCardToken">
          <div class="billing-page__form-grid">
            <div class="billing-page__field billing-page__field--full">
              <label class="billing-page__label" for="mp-cardholder-name">Cardholder Name</label>
              <BillingInputControl id="mp-cardholder-name" v-model="cardForm.cardholderName" type="text"
                autocomplete="cc-name" required />
            </div>

            <div class="billing-page__field billing-page__field--full">
              <label class="billing-page__label" for="mp-card-number">Card Number</label>
              <BillingInputControl id="mp-card-number" v-model="cardForm.cardNumber" type="text" inputmode="numeric"
                autocomplete="cc-number" placeholder="5031 4332 1540 6351" required />
            </div>

            <div class="billing-page__field">
              <label class="billing-page__label" for="mp-exp-month">Exp. Month</label>
              <BillingInputControl id="mp-exp-month" v-model="cardForm.cardExpirationMonth" type="text"
                inputmode="numeric" autocomplete="cc-exp-month" placeholder="MM" required />
            </div>

            <div class="billing-page__field">
              <label class="billing-page__label" for="mp-exp-year">Exp. Year</label>
              <BillingInputControl id="mp-exp-year" v-model="cardForm.cardExpirationYear" type="text"
                inputmode="numeric" autocomplete="cc-exp-year" placeholder="YY o YYYY" required />
            </div>

            <div class="billing-page__field">
              <label class="billing-page__label" for="mp-security-code">CVV</label>
              <BillingInputControl id="mp-security-code" v-model="cardForm.securityCode" type="text"
                inputmode="numeric" autocomplete="cc-csc" placeholder="123" required />
            </div>

            <div class="billing-page__field">
              <label class="billing-page__label" for="mp-identification-type">Document Type</label>
              <BillingInputControl id="mp-identification-type" as="select" v-model="cardForm.identificationType"
                :options="identificationTypeOptions" select-placeholder="Select"
                :disabled="isInitializingMercadoPago || !identificationTypeOptions.length" required />
            </div>

            <div class="billing-page__field billing-page__field--full">
              <label class="billing-page__label" for="mp-identification-number">Document Number</label>
              <BillingInputControl id="mp-identification-number" v-model="cardForm.identificationNumber" type="text"
                inputmode="numeric" autocomplete="off" required />
            </div>
          </div>

          <BillingActionButton type="submit" variant="primary" large icon="lock" loading-icon="loader"
            :loading="isCreatingCheckout || isInitializingMercadoPago" :disabled="!canSubmitCardForm">
            {{ isCreatingCheckout ? providerProfile.cardLoadingCta : providerProfile.cardCta }}
          </BillingActionButton>
        </form>

        <p v-if="mercadoPagoInitError" class="billing-page__form-hint billing-page__form-hint--warning">
          {{ mercadoPagoInitError }}
        </p>

        <div v-if="providerProfile.supportsInlineCardForm && showInlineCardForm" class="billing-page__divider">
          <span>or</span>
        </div>
      </div>
    </div>

    <!-- Error Display -->
    <div v-if="checkoutError" class="billing-page__error">
      <CIcon icon="alert-circle" :size="18" />
      {{ checkoutError }}
      <button class="billing-page__error-close" @click="checkoutError = ''">
        <CIcon icon="x" :size="16" />
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, shallowRef, markRaw, computed, onMounted, onBeforeUnmount, inject } from 'vue';
import { useHead } from 'unhead';
import { ajax } from '../../lib/Ajax';
import loadScript from '../../lib/load-script';
import CIcon from '@/components/c-icon.vue';
import BillingInputControl from '@/components/billing/BillingInputControl';
import BillingActionButton from '@/components/billing/BillingActionButton';
import {
  buildBillingProviderUiProfile,
  formatProviderLabel,
} from '@/components/billing/provider-ui';

const subscription = ref(null);
const billingProviderKey = ref('');
const isHydratingBilling = ref(true);
const returnedFromCheckout = ref(false);
const showInlineCardForm = ref(false);
const isCreatingCheckout = ref(false);
const checkoutError = ref('');
const isInitializingMercadoPago = ref(false);
const mercadoPagoClient = shallowRef(null);
const mercadoPagoInitError = ref('');
const identificationTypes = ref([]);

const cardForm = ref({
  cardholderName: '',
  cardNumber: '',
  cardExpirationMonth: '',
  cardExpirationYear: '',
  securityCode: '',
  identificationType: '',
  identificationNumber: ''
});

const SiteSettings = inject('SiteSettings');
const currentUser = inject('currentUser');

const MERCADO_PAGO_SDK_URL = 'https://sdk.mercadopago.com/js/v2';
let mercadoPagoSdkPromise = null;

const subscriptionStatusClass = computed(() => {
  if (!subscription.value) return 'inactive';
  const status = (subscription.value.status || '').toLowerCase();
  if (['active', 'approved'].includes(status)) return 'active';
  if (['pending', 'in_process'].includes(status)) return 'pending';
  if (['cancelled', 'canceled', 'rejected'].includes(status)) return 'cancelled';
  return 'inactive';
});

const subscriptionStatusIcon = computed(() => {
  switch (subscriptionStatusClass.value) {
    case 'active': return 'check-circle';
    case 'pending': return 'clock';
    case 'cancelled': return 'x-circle';
    default: return 'alert-circle';
  }
});

const subscriptionStatusBadgeIcon = computed(() => {
  switch (subscriptionStatusClass.value) {
    case 'active': return 'check';
    case 'pending': return 'loader';
    case 'cancelled': return 'x';
    default: return 'alert-circle';
  }
});

const canCancel = computed(() => {
  if (!subscription.value) return false;
  const status = (subscription.value.status || '').toLowerCase();
  return ['active', 'approved'].includes(status);
});

const activeProviderKey = computed(() => {
  const fromSubscription = String(subscription.value?.provider || '').trim().toLowerCase();
  const fromBillingResponse = String(billingProviderKey.value || '').trim().toLowerCase();
  const fromSettings = String(SiteSettings?.subscription_provider_primary || '').trim().toLowerCase();

  return fromSubscription || fromBillingResponse || fromSettings || 'mercado_pago';
});

const providerProfile = computed(() => buildBillingProviderUiProfile(activeProviderKey.value, SiteSettings));

const mercadoPagoPublicKey = computed(() => providerProfile.value.sdkPublicKey);

const identificationTypeOptions = computed(() => identificationTypes.value.map((identificationType) => ({
  value: identificationType.id,
  label: identificationType.name,
})));

const isAwaitingActivation = computed(() => {
  return returnedFromCheckout.value && !subscription.value && Boolean(pollingInterval.value);
});

const canSubmitCardForm = computed(() => {
  if (
    !providerProfile.value.supportsInlineCardForm ||
    providerProfile.value.key !== 'mercado_pago' ||
    isCreatingCheckout.value ||
    isInitializingMercadoPago.value ||
    !mercadoPagoClient.value
  ) {
    return false;
  }

  return Boolean(
    cardForm.value.cardholderName.trim() &&
    sanitizeDigits(cardForm.value.cardNumber).length >= 13 &&
    sanitizeDigits(cardForm.value.cardExpirationMonth).length >= 1 &&
    sanitizeDigits(cardForm.value.cardExpirationYear).length >= 2 &&
    sanitizeDigits(cardForm.value.securityCode).length >= 3 &&
    cardForm.value.identificationType &&
    sanitizeDigits(cardForm.value.identificationNumber).length >= 5
  );
});

const sanitizeDigits = (value) => String(value || '').replace(/\D+/g, '');

const normalizeExpirationYear = (value) => {
  const digits = sanitizeDigits(value);
  if (digits.length === 2) {
    return `20${digits}`;
  }

  return digits;
};

const fallbackIdentificationTypeForSite = () => {
  const siteId = String(SiteSettings?.mercadopago_site_id || 'MLU').toUpperCase();

  if (siteId === 'MLA') return 'DNI';
  if (siteId === 'MLB') return 'CPF';
  if (siteId === 'MLC') return 'RUT';
  if (siteId === 'MLM') return 'INE';
  if (siteId === 'MCO') return 'CC';
  return 'CI';
};

const fallbackIdentificationTypes = () => {
  const fallbackType = fallbackIdentificationTypeForSite();
  return [{ id: fallbackType, name: fallbackType }];
};

const mercadoPagoLocaleForSite = () => {
  const siteId = String(SiteSettings?.mercadopago_site_id || 'MLU').toUpperCase();
  const localeBySite = {
    MLA: 'es-AR',
    MLB: 'pt-BR',
    MLC: 'es-CL',
    MLM: 'es-MX',
    MPE: 'es-PE',
    MCO: 'es-CO',
    MLU: 'es-UY'
  };

  return localeBySite[siteId] || 'es-UY';
};

const parseMercadoPagoError = (error) => {
  const cause = error?.cause;
  if (Array.isArray(cause) && cause.length > 0) {
    return cause.map((item) => item?.description || item?.message).filter(Boolean).join(' | ');
  }

  if (typeof cause === 'string' && cause.trim()) {
    return cause;
  }

  return error?.message || 'Could not tokenize the card with the selected provider SDK.';
};

const fetchBillingData = async () => {
  try {
    const { data } = await ajax.get('/account/billing.json');
    billingProviderKey.value = String(data?.provider || billingProviderKey.value || '').trim().toLowerCase();
    return data?.data?.[0] || null;
  } catch (error) {
    console.error('Error fetching billing data:', error);
    return null;
  }
};

const loadMercadoPagoSdk = async () => {
  if (typeof window === 'undefined') return;
  if (window.MercadoPago) return;

  if (!mercadoPagoSdkPromise) {
    mercadoPagoSdkPromise = loadScript(MERCADO_PAGO_SDK_URL);
  }

  await mercadoPagoSdkPromise;
};

const initializeMercadoPago = async () => {
  if (providerProfile.value.key !== 'mercado_pago') {
    return;
  }

  if (mercadoPagoClient.value || isInitializingMercadoPago.value) return;

  if (!mercadoPagoPublicKey.value) {
    mercadoPagoInitError.value = `${providerProfile.value.displayName} public key is missing. Contact the site administrator.`;
    return;
  }

  isInitializingMercadoPago.value = true;
  mercadoPagoInitError.value = '';

  try {
    await loadMercadoPagoSdk();

    const MercadoPago = window.MercadoPago;
    if (typeof MercadoPago !== 'function') {
      throw new Error('MercadoPago.js did not load correctly.');
    }

    mercadoPagoClient.value = markRaw(new MercadoPago(mercadoPagoPublicKey.value, {
      locale: mercadoPagoLocaleForSite()
    }));

    const fetchedTypes = await mercadoPagoClient.value.getIdentificationTypes();
    identificationTypes.value = Array.isArray(fetchedTypes) && fetchedTypes.length > 0
      ? fetchedTypes
      : fallbackIdentificationTypes();

    if (!cardForm.value.identificationType && identificationTypes.value.length > 0) {
      cardForm.value.identificationType = identificationTypes.value[0].id;
    }
  } catch (error) {
    console.error('Error initializing MercadoPago.js:', error);
    mercadoPagoClient.value = null;
    identificationTypes.value = fallbackIdentificationTypes();

    if (!cardForm.value.identificationType && identificationTypes.value.length > 0) {
      cardForm.value.identificationType = identificationTypes.value[0].id;
    }

    mercadoPagoInitError.value = parseMercadoPagoError(error);
  } finally {
    isInitializingMercadoPago.value = false;
  }
};

const createCardToken = async () => {
  if (providerProfile.value.key !== 'mercado_pago') {
    throw new Error(`Inline card tokenization is not available for ${providerProfile.value.displayName}.`);
  }

  await initializeMercadoPago();

  if (!mercadoPagoClient.value) {
    throw new Error(mercadoPagoInitError.value || `${providerProfile.value.displayName} SDK is not ready.`);
  }

  const payload = {
    cardNumber: sanitizeDigits(cardForm.value.cardNumber),
    cardholderName: cardForm.value.cardholderName.trim(),
    cardExpirationMonth: sanitizeDigits(cardForm.value.cardExpirationMonth).slice(0, 2),
    cardExpirationYear: normalizeExpirationYear(cardForm.value.cardExpirationYear).slice(-4),
    securityCode: sanitizeDigits(cardForm.value.securityCode),
    identificationType: cardForm.value.identificationType,
    identificationNumber: sanitizeDigits(cardForm.value.identificationNumber)
  };

  const tokenResponse = await mercadoPagoClient.value.createCardToken(payload);
  const cardTokenId = tokenResponse?.id;

  if (!cardTokenId) {
    throw new Error(`${providerProfile.value.displayName} did not return a valid card token.`);
  }

  return cardTokenId;
};

const createSubscriptionWithCardToken = async () => {
  isCreatingCheckout.value = true;
  checkoutError.value = '';

  try {
    const cardTokenId = await createCardToken();
    const { data } = await ajax.post('/account/billing/subscribe.json', {
      card_token_id: cardTokenId
    });

    const checkoutUrl = data?.data?.checkout_url || data?.data?.sandbox_checkout_url;
    if (checkoutUrl) {
      window.location.href = checkoutUrl;
      return;
    }

    const freshData = await fetchBillingData();
    if (freshData) {
      subscription.value = freshData;
    } else {
      startPolling();
    }
  } catch (error) {
    console.error('Error creating subscription with provider card tokenization:', error);
    checkoutError.value = error?.response?.data?.error || parseMercadoPagoError(error) || 'Could not start subscription.';
  } finally {
    isCreatingCheckout.value = false;
  }
};

const openInlineCardForm = async () => {
  showInlineCardForm.value = true;
  checkoutError.value = '';
  await initializeMercadoPago();
};

const closeInlineCardForm = () => {
  showInlineCardForm.value = false;
};

const createSubscription = async (checkoutMode = null) => {
  isCreatingCheckout.value = true;
  checkoutError.value = '';

  try {
    const payload = checkoutMode ? { checkout_mode: checkoutMode } : {};
    const { data } = await ajax.post('/account/billing/subscribe.json', payload);
    const checkoutUrl = data?.data?.checkout_url || data?.data?.sandbox_checkout_url;

    if (!checkoutUrl) {
      checkoutError.value = `Could not obtain subscription checkout URL for ${providerProfile.value.displayName}.`;
      return;
    }

    window.location.href = checkoutUrl;
  } catch (error) {
    console.error('Error creating subscription:', error);
    checkoutError.value = error?.response?.data?.error || 'Could not start subscription.';
  } finally {
    isCreatingCheckout.value = false;
  }
};

const manageSubscription = () => {
  const managementUrl = subscription.value?.metadata?.management_url
    || subscription.value?.metadata?.manage_url
    || subscription.value?.metadata?.portal_url
    || subscription.value?.metadata?.init_point;

  if (managementUrl) {
    window.location.href = managementUrl;
    return;
  }

  checkoutError.value = `No management portal is available for ${providerProfile.value.displayName} yet.`;
};

const cancelSubscription = async () => {
  if (!confirm('Are you sure you want to cancel your subscription? This action cannot be undone.')) {
    return;
  }

  try {
    await ajax.delete(`/account/billing/subscribe.json`);
    subscription.value = null;
  } catch (error) {
    checkoutError.value = error?.response?.data?.error || 'Failed to cancel subscription.';
  }
};

const formatDate = (value) => {
  if (!value) return 'Not available';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return 'Not available';

  return date.toLocaleDateString('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric'
  });
};

const formatProvider = (provider) => {
  return formatProviderLabel(provider);
};

const pollingInterval = ref(null);

const refreshBillingStatus = async () => {
  isHydratingBilling.value = true;
  try {
    const freshData = await fetchBillingData();
    subscription.value = freshData;
  } finally {
    isHydratingBilling.value = false;
  }
};

// Auto-refresh if no subscription found (user just returned from checkout)
const startPolling = () => {
  if (pollingInterval.value) return;

  pollingInterval.value = setInterval(async () => {
    const freshData = await fetchBillingData();
    if (freshData) {
      subscription.value = freshData;
      stopPolling();
    }
  }, 3000); // Check every 3 seconds

  // Stop after 30 seconds max
  setTimeout(stopPolling, 30000);
};

const stopPolling = () => {
  if (pollingInterval.value) {
    clearInterval(pollingInterval.value);
    pollingInterval.value = null;
  }
};

onMounted(async () => {
  if (!SiteSettings.enable_subscription) {
    isHydratingBilling.value = false;
    return;
  }

  try {
    subscription.value = await fetchBillingData();

    const searchParams = new URLSearchParams(window.location.search);
    returnedFromCheckout.value = ['preapproval_id', 'subscription_id', 'collection_id', 'status']
      .some((param) => searchParams.has(param));

    if (!subscription.value && returnedFromCheckout.value) {
      startPolling();
    }
  } finally {
    isHydratingBilling.value = false;
  }
});

onBeforeUnmount(() => {
  stopPolling();
});

useHead({
  title: 'Manage Subscription',
  meta: [
    {
      name: 'description',
      content: 'Manage your subscription and billing details',
    },
  ],
});
</script>

<style scoped>
.billing-page {
  display: flex;
  flex-direction: column;
  gap: 20px;
  padding: 20px 24px;
  max-width: 900px;
  animation: fadeIn 0.2s ease;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(8px);
  }

  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* ── Header ──────────────────────────────────────────────────────────── */
.billing-page__header {
  padding-bottom: 20px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
}

.billing-page__title {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 1.5rem;
  font-weight: 600;
  color: #fff;
  margin: 0 0 8px 0;
}

.billing-page__icon {
  color: var(--c-tertiary-400, #0095d9);
}

.billing-page__description {
  font-size: 0.85rem;
  color: rgba(255, 255, 255, 0.45);
  margin: 0;
}

/* ── Disabled State ──────────────────────────────────────────────────── */
.billing-page__disabled {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  text-align: center;
}

.billing-page__disabled-icon {
  color: rgba(255, 255, 255, 0.15);
  margin-bottom: 16px;
}

.billing-page__disabled-title {
  font-size: 1.25rem;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.6);
  margin: 0 0 8px 0;
}

.billing-page__disabled-description {
  font-size: 0.85rem;
  color: rgba(255, 255, 255, 0.4);
  margin: 0;
}

/* ── Content ─────────────────────────────────────────────────────────── */
.billing-page__content {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

/* ── Loading State ───────────────────────────────────────────────────── */
.billing-page__loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  padding: 56px 20px;
  border-radius: 12px;
  background: linear-gradient(145deg, rgba(0, 149, 217, 0.08), rgba(0, 0, 0, 0.22));
  border: 1px solid rgba(255, 255, 255, 0.08);
}

.billing-page__loading-icon-wrap {
  width: 46px;
  height: 46px;
  border-radius: 999px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.06);
}

.billing-page__loading-icon {
  color: var(--c-tertiary-400, #0095d9);
  animation: spin 1s linear infinite;
}

.billing-page__loading-title {
  margin: 0;
  font-size: 1.1rem;
  color: #fff;
  font-weight: 600;
}

.billing-page__loading-description {
  margin: 0;
  color: rgba(255, 255, 255, 0.55);
  font-size: 0.85rem;
  text-align: center;
  max-width: 480px;
}

/* ── Status Card ─────────────────────────────────────────────────────── */
.billing-page__card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  padding: 20px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.06);
  border-radius: 8px;
}

.billing-page__card--active {
  border-color: rgba(30, 192, 138, 0.2);
  background: rgba(30, 192, 138, 0.05);
}

.billing-page__card--pending {
  border-color: rgba(255, 193, 7, 0.2);
  background: rgba(255, 193, 7, 0.05);
}

.billing-page__card--cancelled {
  border-color: rgba(255, 120, 120, 0.2);
  background: rgba(255, 120, 120, 0.05);
}

.billing-page__status-header {
  display: flex;
  align-items: center;
  gap: 16px;
}

.billing-page__status-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 56px;
  height: 56px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.06);
}

.billing-page__card--active .billing-page__status-icon {
  background: rgba(30, 192, 138, 0.15);
  color: #1ec08a;
}

.billing-page__card--pending .billing-page__status-icon {
  background: rgba(255, 193, 7, 0.15);
  color: #ffc107;
}

.billing-page__card--cancelled .billing-page__status-icon {
  background: rgba(255, 120, 120, 0.15);
  color: #ff7878;
}

.billing-page__status-info {
  flex: 1;
}

.billing-page__status-title {
  font-size: 1.15rem;
  font-weight: 600;
  color: #fff;
  margin: 0 0 4px 0;
}

.billing-page__status-plan {
  font-size: 0.85rem;
  color: rgba(255, 255, 255, 0.5);
  margin: 0;
}

.billing-page__status-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  border-radius: 12px;
  font-size: 0.775rem;
  font-weight: 600;
  white-space: nowrap;
}

.billing-page__status-badge--active {
  background: rgba(30, 192, 138, 0.15);
  color: #1ec08a;
}

.billing-page__status-badge--pending {
  background: rgba(255, 193, 7, 0.15);
  color: #ffc107;
}

.billing-page__status-badge--cancelled {
  background: rgba(255, 120, 120, 0.15);
  color: #ff7878;
}

.billing-page__status-badge--inactive {
  background: rgba(148, 163, 184, 0.15);
  color: #94a3b8;
}

/* ── Details Section ─────────────────────────────────────────────────── */
.billing-page__details {
  padding: 20px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.06);
  border-radius: 8px;
}

.billing-page__section-title {
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 1.05rem;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.9);
  margin: 0 0 16px 0;
}

.billing-page__details-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 14px;
}

.billing-page__detail-card {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 14px;
  background: rgba(0, 0, 0, 0.2);
  border-radius: 6px;
  border: 1px solid rgba(255, 255, 255, 0.06);
}

.billing-page__detail-icon {
  color: var(--c-tertiary-400, #0095d9);
}

.billing-page__detail-label {
  font-size: 0.725rem;
  color: rgba(255, 255, 255, 0.4);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  font-weight: 500;
}

.billing-page__detail-value {
  font-size: 0.9rem;
  color: rgba(255, 255, 255, 0.9);
  font-weight: 500;
}

/* ── Actions ─────────────────────────────────────────────────────────── */
.billing-page__actions {
  display: flex;
  gap: 12px;
}

/* ── Pending State ───────────────────────────────────────────────────── */
.billing-page__pending {
  display: flex;
  justify-content: center;
  padding: 22px 0;
}

.billing-page__pending-card {
  width: min(620px, 100%);
  padding: 28px;
  border-radius: 12px;
  border: 1px solid rgba(255, 193, 7, 0.28);
  background: linear-gradient(160deg, rgba(255, 193, 7, 0.1), rgba(0, 0, 0, 0.28));
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}

.billing-page__pending-pulse {
  width: 10px;
  height: 10px;
  border-radius: 999px;
  background: #ffc107;
  box-shadow: 0 0 0 rgba(255, 193, 7, 0.6);
  animation: billing-pulse 1.6s infinite;
}

.billing-page__pending-title {
  margin: 0;
  color: #fff;
  font-size: 1.1rem;
}

.billing-page__pending-description {
  margin: 0;
  color: rgba(255, 255, 255, 0.65);
  font-size: 0.86rem;
  max-width: 500px;
}

@keyframes billing-pulse {
  0% {
    transform: scale(1);
    box-shadow: 0 0 0 0 rgba(255, 193, 7, 0.55);
  }

  70% {
    transform: scale(1.05);
    box-shadow: 0 0 0 13px rgba(255, 193, 7, 0);
  }

  100% {
    transform: scale(1);
    box-shadow: 0 0 0 0 rgba(255, 193, 7, 0);
  }
}

/* ── Subscribe Section ───────────────────────────────────────────────── */
.billing-page__subscribe {
  display: flex;
  justify-content: center;
  padding: 40px 0;
}

.billing-page__subscribe-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  padding: 40px;
  background: linear-gradient(155deg, rgba(0, 149, 217, 0.09), rgba(255, 255, 255, 0.02));
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 12px;
  text-align: center;
  max-width: 620px;
}

.billing-page__subscribe-hero {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  border-radius: 999px;
  padding: 8px 14px;
  border: 1px solid rgba(0, 149, 217, 0.35);
  background: rgba(0, 149, 217, 0.14);
}

.billing-page__subscribe-hero-icon {
  color: #8fd4f7;
}

.billing-page__subscribe-hero-kicker {
  color: #c4ecff;
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  font-weight: 700;
}

.billing-page__subscribe-title {
  font-size: 1.35rem;
  font-weight: 600;
  color: #fff;
  margin: 0;
}

.billing-page__subscribe-description {
  font-size: 0.9rem;
  color: rgba(255, 255, 255, 0.7);
  margin: 0;
  max-width: 520px;
}

.billing-page__benefits {
  width: 100%;
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 8px;
  list-style: none;
  margin: 0;
  padding: 0;
}

.billing-page__benefit-item {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 9px 10px;
  border-radius: 8px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  background: rgba(0, 0, 0, 0.22);
  color: rgba(255, 255, 255, 0.78);
  font-size: 0.75rem;
  text-align: left;
}

.billing-page__benefit-icon {
  color: #78dbb1;
  flex-shrink: 0;
}

.billing-page__secure-badge {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 12px;
  border-radius: 999px;
  background: rgba(30, 192, 138, 0.12);
  border: 1px solid rgba(30, 192, 138, 0.25);
  color: #74e4bb;
  font-size: 0.78rem;
  font-weight: 500;
}

.billing-page__form {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-top: 8px;
}

.billing-page__form-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.billing-page__field {
  display: flex;
  flex-direction: column;
  gap: 6px;
  text-align: left;
}

.billing-page__field--full {
  grid-column: span 2;
}

.billing-page__label {
  font-size: 0.74rem;
  color: rgba(255, 255, 255, 0.65);
  text-transform: uppercase;
  letter-spacing: 0.04em;
  font-weight: 600;
}

.billing-page__input {
  width: 100%;
  padding: 10px 12px;
  border-radius: 6px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  background: rgba(0, 0, 0, 0.25);
  color: rgba(255, 255, 255, 0.9);
  font-size: 0.9rem;
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
}

.billing-page__input:focus {
  outline: none;
  border-color: var(--c-tertiary-400, #0095d9);
  box-shadow: 0 0 0 2px rgba(0, 149, 217, 0.2);
}

.billing-page__divider {
  width: 100%;
  position: relative;
  display: flex;
  justify-content: center;
  margin: 6px 0;
}

.billing-page__divider::before {
  content: '';
  position: absolute;
  left: 0;
  right: 0;
  top: 50%;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
}

.billing-page__divider span {
  position: relative;
  padding: 0 10px;
  font-size: 0.78rem;
  color: rgba(255, 255, 255, 0.45);
  background: rgba(22, 25, 34, 1);
}

.billing-page__form-hint {
  margin: 0;
  font-size: 0.8rem;
  color: rgba(255, 255, 255, 0.6);
}

.billing-page__form-hint--warning {
  color: #ffb8a8;
}

/* ── Buttons ─────────────────────────────────────────────────────────── */
.billing-page__btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 10px 20px;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.08);
  color: rgba(255, 255, 255, 0.7);
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
  white-space: nowrap;
}

.billing-page__btn:hover:not(:disabled) {
  background: rgba(255, 255, 255, 0.08);
  color: rgba(255, 255, 255, 0.9);
}

.billing-page__btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.billing-page__btn--primary {
  background: var(--c-tertiary-400, #0095d9);
  border-color: var(--c-tertiary-400, #0095d9);
  color: #fff;
}

.billing-page__btn--primary:hover:not(:disabled) {
  background: var(--c-tertiary-300, #00a8f0);
}

.billing-page__btn--danger {
  background: rgba(255, 120, 120, 0.1);
  border-color: rgba(255, 120, 120, 0.2);
  color: #ff7878;
}

.billing-page__btn--danger:hover:not(:disabled) {
  background: rgba(255, 120, 120, 0.18);
}

.billing-page__btn--large {
  padding: 12px 28px;
  font-size: 0.95rem;
}

.billing-page__btn--spinning {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from {
    transform: rotate(0deg);
  }

  to {
    transform: rotate(360deg);
  }
}

/* ── Error ───────────────────────────────────────────────────────────── */
.billing-page__error {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 16px;
  border-radius: 8px;
  background: rgba(255, 120, 120, 0.08);
  border: 1px solid rgba(255, 120, 120, 0.2);
  color: #ff9494;
  font-size: 0.85rem;
}

.billing-page__error-close {
  margin-left: auto;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 4px;
  border-radius: 4px;
  background: transparent;
  border: none;
  color: rgba(255, 148, 148, 0.7);
  cursor: pointer;
  transition: all 0.15s ease;
}

.billing-page__error-close:hover {
  background: rgba(255, 120, 120, 0.15);
  color: #ff9494;
}

/* ── Mobile Responsive ───────────────────────────────────────────────── */
@media (max-width: 1024px) {
  .billing-page__details-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .billing-page__benefits {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 767px) {
  .billing-page {
    padding: 16px 12px;
  }

  .billing-page__card {
    flex-direction: column;
    align-items: flex-start;
    gap: 14px;
  }

  .billing-page__status-header {
    width: 100%;
  }

  .billing-page__status-badge {
    width: 100%;
    justify-content: center;
  }

  .billing-page__details-grid {
    grid-template-columns: 1fr;
  }

  .billing-page__form-grid {
    grid-template-columns: 1fr;
  }

  .billing-page__field--full {
    grid-column: span 1;
  }

  .billing-page__actions {
    flex-direction: column;
  }

  .billing-page__btn {
    width: 100%;
    justify-content: center;
  }
}
</style>
