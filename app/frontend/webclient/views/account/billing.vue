<template>
  <div class="billing-page">
    <!-- Header -->
    <div class="billing-page__header">
      <div class="billing-page__header-content">
        <h1 class="billing-page__title">
          <CIcon icon="credit-card" :size="28" class="billing-page__icon" />
          Membresía
        </h1>
        <p class="billing-page__description">
          Administra tu suscripción y métodos de pago
        </p>
      </div>
    </div>

    <!-- Subscriptions disabled -->
    <div v-if="!SiteSettings.enable_subscription" class="billing-page__disabled">
      <CIcon icon="credit-card-off" :size="48" class="billing-page__disabled-icon" />
      <h2 class="billing-page__disabled-title">Suscripciones Desactivadas</h2>
      <p class="billing-page__disabled-description">
        El administrador ha desactivado temporalmente las suscripciones de la plataforma.
      </p>
    </div>

    <!-- Initial loading -->
    <div v-else-if="isHydratingBilling" class="billing-page__loading-state">
      <div class="billing-page__loading-icon-wrap">
        <CIcon icon="loader" :size="24" class="billing-page__loading-icon" />
      </div>
      <h2 class="billing-page__loading-title">Cargando tu membresía</h2>
      <p class="billing-page__loading-description">
        Sincronizando estado de tu suscripción…
      </p>
    </div>

    <!-- Active / cancelled subscription -->
    <div v-else-if="subscription && !canSubscribe" class="billing-page__content">
      <div class="billing-plan-card">
        <!-- Status badge -->
        <div class="billing-plan-card__status-row">
          <span class="billing-plan-card__badge" :class="`billing-plan-card__badge--${subscriptionStatusClass}`">
            <CIcon :icon="subscriptionStatusIcon" :size="14" />
            {{ subscription.status_formatted || subscription.status }}
          </span>
          <span v-if="subscription.provider" class="billing-plan-card__provider-tag">
            via {{ formatProvider(subscription.provider) }}
          </span>
        </div>

        <!-- Plan name + cancellation notice -->
        <h2 class="billing-plan-card__title">{{ subscription.product_name || 'CinelarTV+' }}</h2>
        <p class="billing-plan-card__variant">{{ subscription.variant_name || 'Suscripción Mensual' }}</p>

        <div v-if="subscription.cancelled" class="billing-plan-card__cancellation-notice">
          <CIcon icon="alert-circle" :size="16" />
          Suscripción cancelada · Acceso hasta el {{ formatDate(subscription.ends_at) }}.
        </div>

        <!-- Details grid -->
        <div class="billing-plan-card__details">
          <div class="billing-plan-detail" v-if="!subscription.cancelled && subscription.renews_at">
            <span class="billing-plan-detail__label">Próximo cobro</span>
            <span class="billing-plan-detail__value">{{ formatDate(subscription.renews_at) }}</span>
          </div>
          <div class="billing-plan-detail" v-if="subscription.cancelled && subscription.ends_at">
            <span class="billing-plan-detail__label">Acceso hasta el</span>
            <span class="billing-plan-detail__value">{{ formatDate(subscription.ends_at) }}</span>
          </div>
          <div class="billing-plan-detail" v-if="subscription.card_last_four">
            <span class="billing-plan-detail__label">Método de pago</span>
            <span class="billing-plan-detail__value">
              {{ subscription.card_brand?.toUpperCase() || 'Tarjeta' }} ···· {{ subscription.card_last_four }}
            </span>
          </div>
          <div class="billing-plan-detail">
            <span class="billing-plan-detail__label">Email de facturación</span>
            <span class="billing-plan-detail__value">{{ subscription.user_email || currentUser?.email || '—' }}</span>
          </div>
          <div class="billing-plan-detail" v-if="subscription.provider_subscription_id">
            <span class="billing-plan-detail__label">ID de Suscripción</span>
            <span class="billing-plan-detail__value billing-plan-detail__value--mono">{{
              subscription.provider_subscription_id }}</span>
          </div>
          <div class="billing-plan-detail" v-if="lastPaymentInfo">
            <span class="billing-plan-detail__label">Último cobro</span>
            <span class="billing-plan-detail__value">{{ lastPaymentInfo }}</span>
          </div>
        </div>

        <!-- Actions -->
        <div class="billing-plan-card__actions">
          <BillingActionButton icon="refresh-cw" :loading="isSyncing" variant="secondary" @click="manualSync">
            {{ isSyncing ? 'Verificando…' : 'Refrescar estado' }}
          </BillingActionButton>
          <BillingActionButton v-if="hasManagementUrl" icon="external-link" variant="secondary"
            @click="manageSubscription">
            Administrar en {{ formatProvider(subscription.provider) }}
          </BillingActionButton>
          <BillingActionButton v-if="canCancel" icon="x-circle" variant="danger" @click="cancelSubscription">
            Cancelar plan
          </BillingActionButton>
        </div>
      </div>

      <div v-if="payments && payments.length > 0" class="billing-page__history">
        <h3 class="billing-page__history-title">Historial de pagos</h3>
        <div class="billing-page__history-list">
          <div v-for="payment in payments" :key="payment.id" class="billing-page__history-item">
            <div class="billing-page__history-item-left">
              <span class="billing-page__history-date">{{ formatDate(payment.paid_at) }}</span>
              <span class="billing-page__history-status" :class="`billing-page__history-status--${payment.status}`">
                {{ payment.status }}
              </span>
            </div>
            <div class="billing-page__history-item-right">
              <span class="billing-page__history-amount">{{ formatAmount(payment.amount, payment.currency) }}</span>
              <span class="billing-page__history-provider" v-if="payment.provider">
                vía {{ formatProvider(payment.provider) }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Awaiting activation (returned from checkout) -->
    <div v-else-if="isAwaitingActivation" class="billing-page__pending">
      <div class="billing-page__pending-card">
        <div class="billing-page__pending-pulse" />
        <h2 class="billing-page__pending-title">Finalizando tu suscripción</h2>
        <p class="billing-page__pending-description">
          Recibimos tu pago correctamente. La confirmación oficial de {{ providerProfile.displayName }} puede tomar unos
          momentos.
        </p>
        <BillingActionButton icon="refresh-cw" :loading="isSyncing" @click="manualSync">
          {{ isSyncing ? 'Verificando…' : 'Verificar estado de cuenta' }}
        </BillingActionButton>
        <p class="billing-page__pending-hint">
          ¿Ya se activó? Intenta recargar la página.
        </p>
      </div>
    </div>

    <!-- No subscription — subscribe -->
    <div v-else class="billing-page__subscribe">
      <div class="billing-page__subscribe-card">
        <!-- Hero -->
        <div class="billing-page__subscribe-hero">
          <CIcon icon="sparkles" :size="26" class="billing-page__subscribe-hero-icon" />
          <span class="billing-page__subscribe-hero-kicker">CinelarTV Premium</span>
        </div>

        <h2 class="billing-page__subscribe-title">Streaming ilimitado, un solo plan</h2>

        <!-- Benefits -->
        <ul class="billing-page__benefits">
          <li class="billing-page__benefit-item">
            <CIcon icon="check-circle" :size="16" class="billing-page__benefit-icon" />
            Acceso total a nuestro catálogo
          </li>
          <li class="billing-page__benefit-item">
            <CIcon icon="check-circle" :size="16" class="billing-page__benefit-icon" />
            Continúa viendo en todos tus dispositivos
          </li>
          <li class="billing-page__benefit-item">
            <CIcon icon="check-circle" :size="16" class="billing-page__benefit-icon" />
            Soporte técnico prioritario
          </li>
        </ul>
        <!-- Provider selector (multi-provider) -->
        <div v-if="showProviderSelector" class="billing-page__provider-selector">
          <span class="billing-page__provider-selector-label">Paga inicialmente con:</span>
          <div class="billing-page__provider-options">
            <button v-for="provider in enabledProviders" :key="provider.key" class="billing-page__provider-option"
              :class="{ 'billing-page__provider-option--active': activeProviderKey === provider.key }"
              @click="selectProvider(provider.key)">
              <CIcon icon="credit-card" :size="18" />
              {{ provider.label }}
            </button>
          </div>
        </div>

        <!-- Google Play Alert -->
        <div v-if="activeProviderKey === 'google_play'" class="billing-page__google-play-alert">
          <div class="billing-page__alert-content">
            <CIcon icon="smartphone" :size="20" class="billing-page__alert-icon" />
            <div class="billing-page__alert-text">
              <h4>Suscripciones de Google Play</h4>
              <p>Las suscripciones de Google Play solo están disponibles en la app móvil de CinelarTV para Android.</p>
              <div class="billing-page__alert-actions">
                <a href="https://play.google.com/store/apps/details?id=com.abstudios.cinelar.mediaclient"
                  target="_blank" class="billing-page__alert-link">
                  <CIcon icon="download" :size="14" />
                  Descargar app
                </a>
                <BillingActionButton @click="selectNonGooglePlayProvider" variant="secondary">
                  Ver otras opciones
                </BillingActionButton>
              </div>
            </div>
          </div>
        </div>

        <!-- Primary CTA -->
        <BillingActionButton v-else id="billing-subscribe-btn" large icon="external-link" loading-icon="loader"
          variant="primary" :loading="isCreatingCheckout && selectedCheckoutMode === 'redirect'"
          :disabled="isCreatingCheckout" @click="createSubscription('redirect')">
          {{ isCreatingCheckout && selectedCheckoutMode === 'redirect'
            ? providerProfile.checkoutLoadingCta
            : providerProfile.checkoutCta }}
        </BillingActionButton>

        <!-- Secondary payment options -->
        <div v-if="providerProfile.supportsWalletCheckout || providerProfile.supportsInlineCardForm"
          class="billing-page__alt-methods">
          <span class="billing-page__alt-methods-label">Otras formas de pago:</span>
          <div class="billing-page__alt-methods-list">
            <button v-if="providerProfile.supportsWalletCheckout" class="billing-page__alt-btn"
              :class="{ 'billing-page__alt-btn--active': selectedPayMethod === 'wallet' }"
              :disabled="isCreatingCheckout"
              @click="selectedPayMethod = selectedPayMethod === 'wallet' ? null : 'wallet'">
              <CIcon icon="wallet" :size="15" />
              Dinero en cuenta
            </button>
            <button v-if="providerProfile.supportsInlineCardForm" class="billing-page__alt-btn"
              :class="{ 'billing-page__alt-btn--active': selectedPayMethod === 'card' }" :disabled="isCreatingCheckout"
              @click="toggleCardForm">
              <CIcon icon="credit-card" :size="15" />
              Ingresar tarjeta
            </button>
          </div>
        </div>

        <!-- Wallet CTA (secondary, shown when selected) -->
        <div v-if="selectedPayMethod === 'wallet'" class="billing-page__secondary-action">
          <BillingActionButton icon="dollar-sign" loading-icon="loader"
            :loading="isCreatingCheckout && selectedCheckoutMode === 'wallet_balance'" :disabled="isCreatingCheckout"
            @click="createSubscription('wallet_balance')">
            {{ isCreatingCheckout && selectedCheckoutMode === 'wallet_balance'
              ? providerProfile.walletLoadingCta
              : providerProfile.walletCta }}
          </BillingActionButton>
        </div>

        <!-- Inline card form (secondary, shown when selected) -->
        <form v-if="selectedPayMethod === 'card' && providerProfile.supportsInlineCardForm" class="billing-page__form"
          @submit.prevent="createSubscriptionWithCardToken">

          <div v-if="isInitializingMercadoPago" class="billing-page__form-loading">
            <CIcon icon="loader" :size="18" class="animate-spin" />
            Inicializando formulario seguro…
          </div>

          <template v-else>
            <div class="billing-page__secure-badge">
              <CIcon icon="shield-check" :size="15" />
              {{ providerProfile.secureBadgeText }}
            </div>

            <div class="billing-page__form-grid">
              <div class="billing-page__field billing-page__field--full">
                <label class="billing-page__label" for="mp-cardholder-name">Nombre del titular</label>
                <BillingInputControl id="mp-cardholder-name" v-model="cardForm.cardholderName" type="text"
                  autocomplete="cc-name" required />
              </div>

              <div class="billing-page__field billing-page__field--full">
                <label class="billing-page__label" for="mp-card-number">Número de la tarjeta</label>
                <BillingInputControl id="mp-card-number" v-model="cardForm.cardNumber" type="text" inputmode="numeric"
                  autocomplete="cc-number" placeholder="5031 4332 1540 6351" required />
              </div>

              <div class="billing-page__field">
                <label class="billing-page__label" for="mp-exp-month">Mes (MM)</label>
                <BillingInputControl id="mp-exp-month" v-model="cardForm.cardExpirationMonth" type="text"
                  inputmode="numeric" autocomplete="cc-exp-month" placeholder="MM" required />
              </div>

              <div class="billing-page__field">
                <label class="billing-page__label" for="mp-exp-year">Año (AA)</label>
                <BillingInputControl id="mp-exp-year" v-model="cardForm.cardExpirationYear" type="text"
                  inputmode="numeric" autocomplete="cc-exp-year" placeholder="YY" required />
              </div>

              <div class="billing-page__field">
                <label class="billing-page__label" for="mp-security-code">CVV</label>
                <BillingInputControl id="mp-security-code" v-model="cardForm.securityCode" type="text"
                  inputmode="numeric" autocomplete="cc-csc" placeholder="123" required />
              </div>

              <div class="billing-page__field">
                <label class="billing-page__label" for="mp-identification-type">Documento</label>
                <BillingInputControl id="mp-identification-type" as="select" v-model="cardForm.identificationType"
                  :options="identificationTypeOptions" select-placeholder="Select"
                  :disabled="!identificationTypeOptions.length" required />
              </div>

              <div class="billing-page__field billing-page__field--full">
                <label class="billing-page__label" for="mp-identification-number">Número</label>
                <BillingInputControl id="mp-identification-number" v-model="cardForm.identificationNumber" type="text"
                  inputmode="numeric" autocomplete="off" required />
              </div>
            </div>

            <BillingActionButton type="submit" variant="primary" large icon="lock" loading-icon="loader"
              :loading="isCreatingCheckout" :disabled="!canSubmitCardForm">
              {{ isCreatingCheckout ? providerProfile.cardLoadingCta : providerProfile.cardCta }}
            </BillingActionButton>
          </template>
        </form>

        <p v-if="mercadoPagoInitError" class="billing-page__form-hint billing-page__form-hint--warning">
          {{ mercadoPagoInitError }}
        </p>
      </div>
    </div>

    <!-- Error toast -->
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
import { ref, shallowRef, markRaw, computed, onMounted, onBeforeUnmount, inject, nextTick } from 'vue';
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

// ─── State ───────────────────────────────────────────────────────────────────
const subscription = ref(null);
const payments = ref([]);
const billingProviderKey = ref('');
const isHydratingBilling = ref(true);
const isSyncing = ref(false);
const returnedFromCheckout = ref(false);
const isCreatingCheckout = ref(false);
const selectedCheckoutMode = ref(null);   // tracks which CTA is loading
const checkoutError = ref('');
const isInitializingMercadoPago = ref(false);
const mercadoPagoClient = shallowRef(null);
const mercadoPagoInitError = ref('');
const identificationTypes = ref([]);
const enabledProviders = ref([]);
const selectedProviderKey = ref('');
const selectedPayMethod = ref(null);    // null | 'wallet' | 'card'

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

// ─── Computed ─────────────────────────────────────────────────────────────────
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

const canCancel = computed(() => {
  if (!subscription.value) return false;
  const status = (subscription.value.status || '').toLowerCase();
  return ['active', 'approved'].includes(status) && !subscription.value.cancelled;
});

const canSubscribe = computed(() => {
  if (!subscription.value) return true;

  const status = (subscription.value.status || '').toLowerCase();
  const isInactiveStatus = ['cancelled', 'canceled', 'rejected', 'expired'].includes(status);
  const isCancelled = subscription.value.cancelled;

  // Check if subscription has expired
  let isExpired = false;
  if (subscription.value.ends_at) {
    const endDate = new Date(subscription.value.ends_at);
    isExpired = endDate < new Date();
  }

  // Allow subscription if status is inactive, cancelled, or expired
  return isInactiveStatus || isCancelled || isExpired;
});

const hasManagementUrl = computed(() => {
  const meta = subscription.value?.metadata || {};
  return !!(
    meta.customer_portal
    || meta.customer_portal_update_subscription
    || meta.update_payment_method_url
    || meta.management_url
    || meta.manage_url
    || meta.portal_url
    || meta.init_point
  );
});

const lastPaymentInfo = computed(() => {
  const meta = subscription.value?.metadata || {};
  if (!meta.last_payment_date) return null;
  const date = new Date(meta.last_payment_date);
  if (Number.isNaN(date.getTime())) return null;
  const amount = meta.last_payment_amount ? ` · $${Number(meta.last_payment_amount).toFixed(2)}` : '';
  return `${date.toLocaleDateString('es-UY', { month: 'short', day: 'numeric', year: 'numeric' })}${amount}`;
});

const activeProviderKey = computed(() => {
  return (
    String(subscription.value?.provider || '').trim().toLowerCase()
    || String(selectedProviderKey.value || '').trim().toLowerCase()
    || String(billingProviderKey.value || '').trim().toLowerCase()
    || String(SiteSettings?.subscription_provider_primary || '').trim().toLowerCase()
    || 'mercado_pago'
  );
});

const hasMultipleProviders = computed(() => enabledProviders.value.length > 1);
const showProviderSelector = computed(() => !subscription.value && hasMultipleProviders.value);
const providerProfile = computed(() => buildBillingProviderUiProfile(activeProviderKey.value, SiteSettings));
const mercadoPagoPublicKey = computed(() => providerProfile.value.sdkPublicKey);

const identificationTypeOptions = computed(() =>
  identificationTypes.value.map((t) => ({ value: t.id, label: t.name }))
);

// Awaiting activation: user returned from MP checkout but subscription not confirmed yet
const isAwaitingActivation = computed(() => returnedFromCheckout.value && !subscription.value);

const canSubmitCardForm = computed(() => {
  if (
    !providerProfile.value.supportsInlineCardForm
    || providerProfile.value.key !== 'mercado_pago'
    || isCreatingCheckout.value
    || isInitializingMercadoPago.value
    || !mercadoPagoClient.value
  ) return false;

  return Boolean(
    cardForm.value.cardholderName.trim()
    && sanitizeDigits(cardForm.value.cardNumber).length >= 13
    && sanitizeDigits(cardForm.value.cardExpirationMonth).length >= 1
    && sanitizeDigits(cardForm.value.cardExpirationYear).length >= 2
    && sanitizeDigits(cardForm.value.securityCode).length >= 3
    && cardForm.value.identificationType
    && sanitizeDigits(cardForm.value.identificationNumber).length >= 5
  );
});

// ─── Helpers ──────────────────────────────────────────────────────────────────
const sanitizeDigits = (v) => String(v || '').replace(/\D+/g, '');
const normalizeExpirationYear = (v) => {
  const d = sanitizeDigits(v);
  return d.length === 2 ? `20${d}` : d;
};

const formatDate = (value) => {
  if (!value) return '—';
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return '—';
  return d.toLocaleDateString('es-UY', { month: 'long', day: 'numeric', year: 'numeric' });
};

const formatAmount = (amount, currency) => {
  const num = Number(amount) || 0;
  return new Intl.NumberFormat('es-UY', { style: 'currency', currency: currency || 'UYU' }).format(num);
};

const formatProvider = (provider) => formatProviderLabel(provider);

const parseMercadoPagoError = (error) => {
  const cause = error?.cause;
  if (Array.isArray(cause) && cause.length > 0)
    return cause.map((i) => i?.description || i?.message).filter(Boolean).join(' | ');
  if (typeof cause === 'string' && cause.trim()) return cause;
  return error?.message || 'Could not tokenize the card.';
};

const fallbackIdentificationTypeForSite = () => {
  const siteId = String(SiteSettings?.mercadopago_site_id || 'MLU').toUpperCase();
  const map = { MLA: 'DNI', MLB: 'CPF', MLC: 'RUT', MLM: 'INE', MCO: 'CC' };
  return map[siteId] || 'CI';
};

const fallbackIdentificationTypes = () => {
  const t = fallbackIdentificationTypeForSite();
  return [{ id: t, name: t }];
};

const mercadoPagoLocaleForSite = () => {
  const siteId = String(SiteSettings?.mercadopago_site_id || 'MLU').toUpperCase();
  const map = { MLA: 'es-AR', MLB: 'pt-BR', MLC: 'es-CL', MLM: 'es-MX', MPE: 'es-PE', MCO: 'es-CO', MLU: 'es-UY' };
  return map[siteId] || 'es-UY';
};

// ─── MP SDK ──────────────────────────────────────────────────────────────────
const loadMercadoPagoSdk = async () => {
  if (typeof window === 'undefined' || window.MercadoPago) return;
  if (!mercadoPagoSdkPromise) mercadoPagoSdkPromise = loadScript(MERCADO_PAGO_SDK_URL);
  await mercadoPagoSdkPromise;
};

const initializeMercadoPago = async () => {
  if (providerProfile.value.key !== 'mercado_pago') return;
  if (mercadoPagoClient.value || isInitializingMercadoPago.value) return;

  if (!mercadoPagoPublicKey.value) {
    mercadoPagoInitError.value = `${providerProfile.value.displayName} public key is missing. Contact support.`;
    return;
  }

  isInitializingMercadoPago.value = true;
  mercadoPagoInitError.value = '';

  try {
    await loadMercadoPagoSdk();
    const MP = window.MercadoPago;
    if (typeof MP !== 'function') throw new Error('MercadoPago.js did not load correctly.');

    mercadoPagoClient.value = markRaw(new MP(mercadoPagoPublicKey.value, {
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
    if (!cardForm.value.identificationType) {
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

  const tokenResponse = await mercadoPagoClient.value.createCardToken({
    cardNumber: sanitizeDigits(cardForm.value.cardNumber),
    cardholderName: cardForm.value.cardholderName.trim(),
    cardExpirationMonth: sanitizeDigits(cardForm.value.cardExpirationMonth).slice(0, 2),
    cardExpirationYear: normalizeExpirationYear(cardForm.value.cardExpirationYear).slice(-4),
    securityCode: sanitizeDigits(cardForm.value.securityCode),
    identificationType: cardForm.value.identificationType,
    identificationNumber: sanitizeDigits(cardForm.value.identificationNumber)
  });

  const cardTokenId = tokenResponse?.id;
  if (!cardTokenId) throw new Error(`${providerProfile.value.displayName} did not return a valid card token.`);
  return cardTokenId;
};

// ─── Data fetching ────────────────────────────────────────────────────────────
const fetchBillingData = async () => {
  const { data } = await ajax.get('/account/billing.json');
  billingProviderKey.value = String(data?.provider || billingProviderKey.value || '').trim().toLowerCase();

  if (Array.isArray(data?.payments)) {
    payments.value = data.payments;
  }

  if (Array.isArray(data?.enabled_providers) && data.enabled_providers.length > 0) {
    enabledProviders.value = data.enabled_providers;
  }
  return data?.data?.[0] || null;
};

// ─── Manual sync (replaces auto-polling) ─────────────────────────────────────
const manualSync = async () => {
  if (isSyncing.value) return;
  isSyncing.value = true;
  checkoutError.value = '';
  try {
    if (subscription.value) {
      // Try provider sync first
      try {
        const { data } = await ajax.post('/account/billing/sync.json', {});
        subscription.value = data?.data || subscription.value;
      } catch {
        subscription.value = await fetchBillingData();
      }
    } else {
      // No subscription yet — just refetch
      subscription.value = await fetchBillingData();
    }
  } catch (error) {
    checkoutError.value = error?.response?.data?.error || 'Could not refresh status.';
  } finally {
    isSyncing.value = false;
  }
};

// ─── Subscription actions ─────────────────────────────────────────────────────
const createSubscription = async (mode = 'redirect') => {
  isCreatingCheckout.value = true;
  selectedCheckoutMode.value = mode;
  checkoutError.value = '';

  try {
    const payload = { checkout_mode: mode === 'redirect' ? null : mode };
    if (selectedProviderKey.value) payload.provider = selectedProviderKey.value;

    const { data } = await ajax.post('/account/billing/subscribe.json', payload);
    const provider = String(data?.data?.provider || activeProviderKey.value).toLowerCase();

    if (provider === 'lemon_squeezy') {
      const checkoutUrl = data?.data?.checkout_url;
      if (!checkoutUrl) {
        checkoutError.value = `Could not obtain checkout URL for ${providerProfile.value.displayName}.`;
        return;
      }
      // LemonSqueezy overlay — SDK loaded from layout
      let attempts = 0;
      while (!window.LemonSqueezy?.Url?.Open && attempts < 50) {
        await new Promise((r) => setTimeout(r, 100));
        attempts++;
      }
      if (!window.LemonSqueezy?.Url?.Open) throw new Error('Lemon Squeezy SDK failed to load.');
      window.LemonSqueezy.Url.Open(checkoutUrl);
      returnedFromCheckout.value = true;
    } else {
      // MercadoPago and all other providers → redirect
      const checkoutUrl = data?.data?.checkout_url || data?.data?.sandbox_checkout_url;
      if (!checkoutUrl) {
        checkoutError.value = `Could not obtain checkout URL for ${providerProfile.value.displayName}.`;
        return;
      }
      window.location.href = checkoutUrl;
    }
  } catch (error) {
    console.error('Error creating subscription:', error);
    checkoutError.value = error?.response?.data?.error || 'Could not start subscription. Please try again.';
  } finally {
    isCreatingCheckout.value = false;
    selectedCheckoutMode.value = null;
  }
};

const createSubscriptionWithCardToken = async () => {
  isCreatingCheckout.value = true;
  checkoutError.value = '';

  try {
    const cardTokenId = await createCardToken();
    const { data } = await ajax.post('/account/billing/subscribe.json', { card_token_id: cardTokenId });

    const checkoutUrl = data?.data?.checkout_url || data?.data?.sandbox_checkout_url;
    if (checkoutUrl) {
      window.location.href = checkoutUrl;
      return;
    }

    // If no redirect needed, refresh billing data
    subscription.value = await fetchBillingData();
    if (!subscription.value) returnedFromCheckout.value = true;
  } catch (error) {
    console.error('Error creating subscription with card tokenization:', error);
    checkoutError.value = error?.response?.data?.error || parseMercadoPagoError(error) || 'Could not start subscription.';
  } finally {
    isCreatingCheckout.value = false;
  }
};

const manageSubscription = () => {
  const meta = subscription.value?.metadata || {};
  const url = meta.customer_portal
    || meta.customer_portal_update_subscription
    || meta.update_payment_method_url
    || meta.management_url
    || meta.manage_url
    || meta.portal_url
    || meta.init_point;
  if (url) window.open(url, '_blank');
};

const selectNonGooglePlayProvider = () => {
  // Debug: Log available providers
  console.log('Available providers:', enabledProviders.value);
  console.log('Current active provider:', activeProviderKey.value);

  // Find first non-Google Play provider
  const nonGooglePlayProvider = enabledProviders.value.find(p => p.key !== 'google_play');
  console.log('Non-Google Play provider found:', nonGooglePlayProvider);

  if (nonGooglePlayProvider) {
    // Force update selected provider and clear any errors
    selectedProviderKey.value = nonGooglePlayProvider.key;
    selectedPayMethod.value = null;
    checkoutError.value = '';

    // Force UI update
    nextTick(() => {
      console.log('Selected provider set to:', selectedProviderKey.value);
      console.log('Active provider computed:', activeProviderKey.value);
    });
  } else {
    // If no other providers available, show message
    checkoutError.value = 'No hay otros proveedores de pago disponibles en este momento. Por favor, descarga la app móvil para suscribirte con Google Play.';
  }
};

const cancelSubscription = async () => {
  const endDate = subscription.value?.ends_at
    ? new Date(subscription.value.ends_at).toLocaleDateString('es-UY', { month: 'long', day: 'numeric', year: 'numeric' })
    : 'su próximo ciclo de facturación';

  if (!confirm(`Tu suscripción será cancelada, pero mantendrás tu acceso al catálogo hasta el día: ${endDate}. ¿Deseas continuar?`)) return;

  try {
    await ajax.delete('/account/billing/subscribe.json');
    subscription.value = await fetchBillingData();
    checkoutError.value = '';
  } catch (error) {
    checkoutError.value = error?.response?.data?.error || 'Failed to cancel subscription.';
  }
};

const selectProvider = (key) => {
  selectedProviderKey.value = key;
  selectedPayMethod.value = null;
  checkoutError.value = '';
};

const toggleCardForm = async () => {
  if (selectedPayMethod.value === 'card') {
    selectedPayMethod.value = null;
    return;
  }
  selectedPayMethod.value = 'card';
  checkoutError.value = '';
  await initializeMercadoPago();
};

// ─── Focus listener — sync when tab regains focus ─────────────────────────────
let handleWindowFocusRef = null;

const setupFocusListener = () => {
  handleWindowFocusRef = async () => {
    // Only auto-sync if user came back from checkout and hasn't confirmed yet
    if (returnedFromCheckout.value && !subscription.value) {
      await manualSync();
    }
  };
  window.addEventListener('focus', handleWindowFocusRef);
};

const removeFocusListener = () => {
  if (handleWindowFocusRef) {
    window.removeEventListener('focus', handleWindowFocusRef);
    handleWindowFocusRef = null;
  }
};

// ─── Lifecycle ────────────────────────────────────────────────────────────────
onMounted(async () => {
  if (!SiteSettings.enable_subscription) {
    isHydratingBilling.value = false;
    return;
  }

  try {
    subscription.value = await fetchBillingData();

    const searchParams = new URLSearchParams(window.location.search);
    returnedFromCheckout.value = ['preapproval_id', 'subscription_id', 'collection_id', 'status']
      .some((p) => searchParams.has(p));

    // If returned from checkout with no subscription, try one sync
    if (!subscription.value && returnedFromCheckout.value) {
      await manualSync();
    }
    // If subscription is pending, sync from provider once
    else if (subscription.value?.status === 'pending') {
      try {
        const { data } = await ajax.post('/account/billing/sync.json', {});
        if (data?.data) subscription.value = data.data;
      } catch {
        // ignore — status will be shown as-is
      }
    }

    setupFocusListener();
  } finally {
    isHydratingBilling.value = false;
  }
});

onBeforeUnmount(() => {
  removeFocusListener();
});

useHead({
  title: 'Membership',
  meta: [{ name: 'description', content: 'Manage your CinelarTV subscription and billing details.' }],
});
</script>
