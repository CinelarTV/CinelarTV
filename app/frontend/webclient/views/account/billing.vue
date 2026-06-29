<template>
  <div class="billing-page">
    <!-- Header -->
    <div class="billing-page__header">
      <div class="billing-page__header-content">
        <h1 class="billing-page__title">
          <CIcon icon="credit-card" :size="28" class="billing-page__icon" />
          {{ $t('js.billing.title') }}
        </h1>
        <p class="billing-page__description">
          {{ $t('js.billing.description') }}
        </p>
      </div>
    </div>

    <!-- Subscriptions disabled -->
    <div v-if="!SiteSettings.enable_subscription" class="billing-page__disabled">
      <CIcon icon="credit-card-off" :size="48" class="billing-page__disabled-icon" />
      <h2 class="billing-page__disabled-title">{{ $t('js.billing.disabled_title') }}</h2>
      <p class="billing-page__disabled-description">
        {{ $t('js.billing.disabled_description') }}
      </p>
    </div>

    <!-- Initial loading -->
    <div v-else-if="isHydratingBilling" class="billing-page__loading-state">
      <div class="billing-page__loading-icon-wrap">
        <CIcon icon="loader" :size="24" class="billing-page__loading-icon" />
      </div>
      <h2 class="billing-page__loading-title">{{ $t('js.billing.loading_title') }}</h2>
      <p class="billing-page__loading-description">
        {{ $t('js.billing.loading_description') }}
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
        <p class="billing-plan-card__variant">{{ subscription.variant_name || $t('js.billing.active_plan') }}</p>

        <div v-if="subscription.cancelled" class="billing-plan-card__cancellation-notice">
          <CIcon icon="alert-circle" :size="16" />
          {{ $t('js.billing.cancelled_notice', { date: formatDate(subscription.ends_at) }) }}
        </div>

        <!-- Details grid -->
        <div class="billing-plan-card__details">
          <div class="billing-plan-detail" v-if="!subscription.cancelled && subscription.renews_at">
            <span class="billing-plan-detail__label">{{ $t('js.billing.renews_at') }}</span>
            <span class="billing-plan-detail__value">{{ formatDate(subscription.renews_at) }}</span>
          </div>
          <div class="billing-plan-detail" v-if="subscription.cancelled && subscription.ends_at">
            <span class="billing-plan-detail__label">{{ $t('js.billing.ends_at') }}</span>
            <span class="billing-plan-detail__value">{{ formatDate(subscription.ends_at) }}</span>
          </div>
          <div class="billing-plan-detail" v-if="subscription.card_last_four">
            <span class="billing-plan-detail__label">Método de pago</span>
            <span class="billing-plan-detail__value">
              {{ subscription.card_brand?.toUpperCase() || 'Tarjeta' }} ···· {{ subscription.card_last_four }}
            </span>
          </div>
          <div class="billing-plan-detail">
            <span class="billing-plan-detail__label">{{ $t('js.billing.billing_email') }}</span>
            <span class="billing-plan-detail__value">{{ subscription.user_email || currentUser?.email || '—' }}</span>
          </div>
          <div class="billing-plan-detail" v-if="lastPaymentInfo">
            <span class="billing-plan-detail__label">{{ $t('js.billing.last_payment') }}</span>
            <span class="billing-plan-detail__value">{{ lastPaymentInfo }}</span>
          </div>
        </div>

        <!-- Actions -->
        <div class="billing-plan-card__actions">
          <BillingActionButton icon="refresh-cw" :loading="isSyncing" variant="secondary" @click="manualSync">
            {{ isSyncing ? $t('js.billing.syncing') : $t('js.billing.sync') }}
          </BillingActionButton>
          <BillingActionButton v-if="hasManagementUrl" icon="external-link" variant="secondary"
            @click="manageSubscription">
            {{ $t('js.billing.manage_provider', { provider: formatProvider(subscription.provider) }) }}
          </BillingActionButton>
          <BillingActionButton v-if="subscription.cancelled" icon="refresh-cw" variant="primary" @click="resubscribe">
            {{ $t('js.billing.resubscribe') }}
          </BillingActionButton>
          <BillingActionButton v-else-if="canCancel" icon="x-circle" variant="danger" @click="cancelSubscription">
            {{ $t('js.billing.cancel') }}
          </BillingActionButton>
        </div>
      </div>

      <div v-if="payments && payments.length > 0" class="billing-page__history">
        <h3 class="billing-page__history-title">{{ $t('js.billing.payment_history') }}</h3>
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
        <h2 class="billing-page__pending-title">{{ $t('js.billing.awaiting_title') }}</h2>
        <p class="billing-page__pending-description">
          {{ $t('js.billing.awaiting_description', { provider: providerProfile.displayName }) }}
        </p>
        <BillingActionButton icon="refresh-cw" :loading="isSyncing" @click="manualSync">
          {{ isSyncing ? $t('js.billing.syncing') : $t('js.billing.awaiting_sync') }}
        </BillingActionButton>
        <p class="billing-page__pending-hint">
          {{ $t('js.billing.awaiting_hint') }}
        </p>
      </div>
    </div>

    <!-- No subscription — subscribe -->
    <div v-else class="billing-page__subscribe">
      <!-- Web providers checkout card -->
      <div v-if="hasWebProviders" class="billing-page__subscribe-card">

        <!-- Price hero -->
        <div v-if="isFetchingPlan" class="billing-page__price-hero billing-page__price-hero--loading">
          <CIcon icon="loader" :size="20" class="animate-spin" />
        </div>
        <div v-else-if="planData" class="billing-page__price-hero">
          <span class="billing-page__price-amount">${{ Number(planData.amount) || 0 }}</span>
          <span class="billing-page__price-currency">{{ planData.currency }}</span>
          <span class="billing-page__price-period">/{{ planFrequencyText }}</span>
        </div>
        <div v-else class="billing-page__price-hero billing-page__price-hero--unavailable">
          <span class="billing-page__price-amount">{{ $t('js.billing.price_unavailable') }}</span>
        </div>

        <!-- Benefits -->
        <ul class="billing-page__benefits">
          <li class="billing-page__benefit-item">
            <CIcon icon="check-circle" :size="16" class="billing-page__benefit-icon" />
            {{ $t('js.billing.benefits.no_ads') }}
          </li>
          <li class="billing-page__benefit-item">
            <CIcon icon="check-circle" :size="16" class="billing-page__benefit-icon" />
            {{ $t('js.billing.benefits.early_premiere') }}
          </li>
          <li class="billing-page__benefit-item">
            <CIcon icon="check-circle" :size="16" class="billing-page__benefit-icon" />
            {{ $t('js.billing.benefits.quality') }}
          </li>
          <li class="billing-page__benefit-item">
            <CIcon icon="check-circle" :size="16" class="billing-page__benefit-icon" />
            {{ $t('js.billing.benefits.cancel_anytime') }}
          </li>
        </ul>

        <!-- Primary CTA — recommended provider -->
        <BillingActionButton id="billing-subscribe-btn" large icon="external-link" loading-icon="loader"
          variant="primary" :loading="isCreatingCheckout && selectedCheckoutMode === 'redirect'"
          :disabled="isCreatingCheckout" @click="createSubscription('redirect')">
          {{ isCreatingCheckout && selectedCheckoutMode === 'redirect'
            ? providerProfile.checkoutLoadingCta
            : planPrice
              ? $t('js.billing.subscribe_cta', { provider: providerProfile.displayName, price: planPrice })
              : $t('js.billing.subscribe_cta_no_price', { provider: providerProfile.displayName }) }}
        </BillingActionButton>

        <!-- Alternative providers -->
        <div v-if="alternativeProviders.length > 0" class="billing-page__alt-providers">
          <span class="billing-page__alt-providers-label">
            {{ $t('js.billing.alternative_providers', {
              provider: providerProfile.displayName,
              alternative: alternativeProviders[0].label
            }) }}
          </span>
          <button class="billing-page__alt-provider-btn" @click="switchProvider(alternativeProviders[0].key)">
            <CIcon icon="credit-card" :size="15" />
            {{ alternativeProviders[0].label }}
          </button>
        </div>

        <!-- Secondary payment options (wallet + inline card) -->
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
              {{ $t('js.billing.card_form_title') }}
            </button>
          </div>
        </div>

        <!-- Wallet CTA -->
        <div v-if="selectedPayMethod === 'wallet'" class="billing-page__secondary-action">
          <BillingActionButton icon="dollar-sign" loading-icon="loader"
            :loading="isCreatingCheckout && selectedCheckoutMode === 'wallet_balance'" :disabled="isCreatingCheckout"
            @click="createSubscription('wallet_balance')">
            {{ isCreatingCheckout && selectedCheckoutMode === 'wallet_balance'
              ? providerProfile.walletLoadingCta
              : providerProfile.walletCta }}
          </BillingActionButton>
        </div>

        <!-- Inline card form -->
        <form v-if="selectedPayMethod === 'card' && providerProfile.supportsInlineCardForm" class="billing-page__form"
          @submit.prevent="createSubscriptionWithCardToken">

          <div v-if="isInitializingMercadoPago" class="billing-page__form-loading">
            <CIcon icon="loader" :size="18" class="animate-spin" />
            Inicializando formulario seguro...
          </div>

          <template v-else>
            <div class="billing-page__secure-badge">
              <CIcon icon="shield-check" :size="15" />
              {{ $t('js.billing.secure_badge', { provider: providerProfile.displayName }) }}
            </div>

            <div class="billing-page__form-grid">
              <div class="billing-page__field billing-page__field--full">
                <label class="billing-page__label" for="mp-cardholder-name">{{ $t('js.billing.cardholder_name')
                  }}</label>
                <BillingInputControl id="mp-cardholder-name" v-model="cardForm.cardholderName" type="text"
                  autocomplete="cc-name" required />
              </div>

              <div class="billing-page__field billing-page__field--full">
                <label class="billing-page__label" for="mp-card-number">{{ $t('js.billing.card_number') }}</label>
                <BillingInputControl id="mp-card-number" v-model="cardForm.cardNumber" type="text" inputmode="numeric"
                  autocomplete="cc-number" placeholder="5031 4332 1540 6351" required />
              </div>

              <div class="billing-page__field">
                <label class="billing-page__label" for="mp-exp-month">{{ $t('js.billing.exp_month') }}</label>
                <BillingInputControl id="mp-exp-month" v-model="cardForm.cardExpirationMonth" type="text"
                  inputmode="numeric" autocomplete="cc-exp-month" placeholder="MM" required />
              </div>

              <div class="billing-page__field">
                <label class="billing-page__label" for="mp-exp-year">{{ $t('js.billing.exp_year') }}</label>
                <BillingInputControl id="mp-exp-year" v-model="cardForm.cardExpirationYear" type="text"
                  inputmode="numeric" autocomplete="cc-exp-year" placeholder="YY" required />
              </div>

              <div class="billing-page__field">
                <label class="billing-page__label" for="mp-security-code">{{ $t('js.billing.cvv') }}</label>
                <BillingInputControl id="mp-security-code" v-model="cardForm.securityCode" type="text"
                  inputmode="numeric" autocomplete="cc-csc" placeholder="123" required />
              </div>

              <div class="billing-page__field">
                <label class="billing-page__label" for="mp-identification-type">{{ $t('js.billing.id_type') }}</label>
                <BillingInputControl id="mp-identification-type" as="select" v-model="cardForm.identificationType"
                  :options="identificationTypeOptions" select-placeholder="Select"
                  :disabled="!identificationTypeOptions.length" required />
              </div>

              <div class="billing-page__field billing-page__field--full">
                <label class="billing-page__label" for="mp-identification-number">{{ $t('js.billing.id_number')
                  }}</label>
                <BillingInputControl id="mp-identification-number" v-model="cardForm.identificationNumber" type="text"
                  inputmode="numeric" autocomplete="off" required />
              </div>
            </div>

            <BillingActionButton type="submit" variant="primary" large icon="lock" loading-icon="loader"
              :loading="isCreatingCheckout" :disabled="!canSubmitCardForm">
              {{ isCreatingCheckout ? $t('js.billing.processing_card') : $t('js.billing.subscribe_with_card') }}
            </BillingActionButton>
          </template>
        </form>

        <p v-if="mercadoPagoInitError" class="billing-page__form-hint billing-page__form-hint--warning">
          {{ mercadoPagoInitError }}
        </p>
      </div>

      <!-- OpenIAP section — mobile only -->
      <div v-if="isOpenIapEnabled" class="billing-page__mobile-section" :class="{ 'billing-page__mobile-section--standalone': !hasWebProviders }">
        <div class="billing-page__mobile-icon">
          <CIcon icon="smartphone" :size="32" />
        </div>
        <div class="billing-page__mobile-content">
          <h3 class="billing-page__mobile-title">{{ $t('js.billing.mobile_title') }}</h3>
          <p class="billing-page__mobile-description">{{ $t('js.billing.mobile_description') }}</p>
          <div class="billing-page__store-links">
            <a :href="appleAppStoreUrl" target="_blank" rel="noopener" class="billing-page__store-link">
              <img src="@/assets/store-badges/app-store.svg" alt="Download on App Store"
                class="billing-page__store-badge" />
            </a>
            <a :href="googlePlayUrl" target="_blank" rel="noopener" class="billing-page__store-link">
              <img src="@/assets/store-badges/google-play.svg" alt="Get it on Google Play"
                class="billing-page__store-badge" />
            </a>
          </div>
        </div>
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
import { ref, shallowRef, markRaw, computed, watch, onMounted, onBeforeUnmount, inject, nextTick } from 'vue';
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
import { useSubscriptionStore } from '@/app/services/subscription-store';

// ─── Store ────────────────────────────────────────────────────────────────────
const subscriptionStore = useSubscriptionStore();

// ─── State ────────────────────────────────────────────────────────────────────
const isHydratingBilling = ref(true);
const returnedFromCheckout = ref(false);
const isCreatingCheckout = ref(false);
const selectedCheckoutMode = ref(null);
const checkoutError = ref('');
const isInitializingMercadoPago = ref(false);
const mercadoPagoClient = shallowRef(null);
const mercadoPagoInitError = ref('');
const identificationTypes = ref([]);
const selectedProviderKey = ref('');
const selectedPayMethod = ref(null);
const planData = ref(null);
const isFetchingPlan = ref(false);

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

// ─── Computed (from store) ────────────────────────────────────────────────────
const subscription = computed(() => subscriptionStore.subscription);
const payments = computed(() => subscriptionStore.payments);
const isSyncing = computed(() => subscriptionStore.isSyncing);
const enabledProviders = computed(() => subscriptionStore.enabledProviders);
const geoData = computed(() => subscriptionStore.geoData);

const planPrice = computed(() => {
  if (planData.value) {
    const amount = Number(planData.value.amount) || 0;
    const currency = planData.value.currency || 'USD';
    return `${amount} ${currency}`;
  }
  return null;
});

const planFrequencyText = computed(() => {
  if (!planData.value) return null;
  const freq = planData.value.frequency || 1;
  const type = planData.value.frequency_type || 'months';
  if (freq === 1) {
    const labels = { days: 'día', weeks: 'semana', months: 'mes', years: 'año' };
    return labels[type] || type;
  }
  const labels = { days: 'días', weeks: 'semanas', months: 'meses', years: 'años' };
  return `${freq} ${labels[type] || type}`;
});

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
  let isExpired = false;
  if (subscription.value.ends_at) {
    const endDate = new Date(subscription.value.ends_at);
    isExpired = endDate < new Date();
  }
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

// Provider logic — geo-recommended provider
const activeProviderKey = computed(() => {
  return (
    String(subscription.value?.provider || '').trim().toLowerCase()
    || String(selectedProviderKey.value || '').trim().toLowerCase()
    || String(geoData.value.recommended_provider || '').trim().toLowerCase()
    || String(SiteSettings?.subscription_provider_primary || '').trim().toLowerCase()
    || 'mercado_pago'
  );
});

const providerProfile = computed(() => buildBillingProviderUiProfile(activeProviderKey.value, SiteSettings));
const mercadoPagoPublicKey = computed(() => providerProfile.value.sdkPublicKey);

const alternativeProviders = computed(() =>
  enabledProviders.value.filter(p =>
    p.key !== activeProviderKey.value && p.key !== 'open_iap'
  )
);

const hasWebProviders = computed(() =>
  enabledProviders.value.some(p => p.key !== 'open_iap')
);

const isOpenIapEnabled = computed(() =>
  enabledProviders.value.some(p => p.key === 'open_iap')
);

const appleAppStoreUrl = computed(() => SiteSettings?.apple_app_store_url || '#');
const googlePlayUrl = computed(() => SiteSettings?.google_play_store_url || '#');

const identificationTypeOptions = computed(() =>
  identificationTypes.value.map((t) => ({ value: t.id, label: t.name }))
);

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
  const locale = SiteSettings?.default_locale || 'es-UY';
  return d.toLocaleDateString(locale, { month: 'long', day: 'numeric', year: 'numeric' });
};

const formatAmount = (amount, currency) => {
  const num = Number(amount) || 0;
  const locale = SiteSettings?.default_locale || 'es-UY';
  return new Intl.NumberFormat(locale, { style: 'currency', currency: currency || 'UYU' }).format(num);
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

// ─── Manual sync ──────────────────────────────────────────────────────────────
const manualSync = async () => {
  checkoutError.value = '';
  try {
    await subscriptionStore.sync();
    subscriptionStore.refreshCurrentUser(currentUser);
  } catch (error) {
    checkoutError.value = error?.response?.data?.error || 'Could not refresh status.';
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
      let attempts = 0;
      while (!window.LemonSqueezy?.Url?.Open && attempts < 50) {
        await new Promise((r) => setTimeout(r, 100));
        attempts++;
      }
      if (!window.LemonSqueezy?.Url?.Open) throw new Error('Lemon Squeezy SDK failed to load.');
      window.LemonSqueezy.Url.Open(checkoutUrl);
      returnedFromCheckout.value = true;
    } else {
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

    await subscriptionStore.fetchBillingData();
    subscriptionStore.refreshCurrentUser(currentUser);
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

const cancelSubscription = async () => {
  const endDate = subscription.value?.ends_at
    ? formatDate(subscription.value.ends_at)
    : 'su próximo ciclo de facturación';

  const message = `Tu suscripción será cancelada, pero mantendrás tu acceso hasta el: ${endDate}. ¿Deseas continuar?`;
  if (!confirm(message)) return;

  try {
    await subscriptionStore.cancel();
    subscriptionStore.refreshCurrentUser(currentUser);
    checkoutError.value = '';
  } catch (error) {
    checkoutError.value = error?.response?.data?.error || 'Failed to cancel subscription.';
  }
};

const resubscribe = () => {
  // Reset subscription state to show the subscribe view
  subscriptionStore.subscription = null;
};

const switchProvider = (key) => {
  selectedProviderKey.value = key;
  selectedPayMethod.value = null;
  checkoutError.value = '';
};

const fetchPlanForProvider = async (providerKey) => {
  if (!providerKey) return;
  isFetchingPlan.value = true;
  try {
    const { data } = await ajax.get('/account/billing/plan.json', { params: { provider: providerKey } });
    planData.value = data?.data || null;
  } catch {
    planData.value = null;
  } finally {
    isFetchingPlan.value = false;
  }
};

watch(activeProviderKey, (newKey) => {
  if (newKey && newKey !== 'open_iap') {
    fetchPlanForProvider(newKey);
  }
});

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
    await subscriptionStore.fetchBillingData();

    if (activeProviderKey.value && activeProviderKey.value !== 'open_iap') {
      fetchPlanForProvider(activeProviderKey.value);
    }

    const searchParams = new URLSearchParams(window.location.search);
    returnedFromCheckout.value = ['preapproval_id', 'subscription_id', 'collection_id', 'status']
      .some((p) => searchParams.has(p));

    if (!subscription.value && returnedFromCheckout.value) {
      await manualSync();
    } else if (subscription.value?.status === 'pending') {
      try {
        await subscriptionStore.sync();
      } catch {
        // ignore — status will be shown as-is
      }
    }

    subscriptionStore.refreshCurrentUser(currentUser);
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
