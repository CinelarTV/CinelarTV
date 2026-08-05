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
        <h2 class="billing-plan-card__title">CinelarTV</h2>
        <p class="billing-plan-card__variant">{{ $t('js.billing.active_plan') }}</p>

        <div v-if="isCancelled" class="billing-plan-card__cancellation-notice">
          <CIcon icon="alert-circle" :size="16" />
          {{ $t('js.billing.cancelled_notice', { date: formatDate(subscription.ends_at) }) }}
        </div>

        <!-- Details grid -->
        <div class="billing-plan-card__details">
          <div class="billing-plan-detail" v-if="!isCancelled && subscription.renews_at">
            <span class="billing-plan-detail__label">{{ $t('js.billing.renews_at') }}</span>
            <span class="billing-plan-detail__value">{{ formatDate(subscription.renews_at) }}</span>
          </div>
          <div class="billing-plan-detail" v-if="isCancelled && subscription.ends_at">
            <span class="billing-plan-detail__label">{{ $t('js.billing.ends_at') }}</span>
            <span class="billing-plan-detail__value">{{ formatDate(subscription.ends_at) }}</span>
          </div>
          <div class="billing-plan-detail">
            <span class="billing-plan-detail__label">{{ $t('js.billing.billing_email') }}</span>
            <span class="billing-plan-detail__value">{{ currentUser?.email || '—' }}</span>
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
          <BillingActionButton v-if="isCancelled" icon="refresh-cw" variant="primary" @click="resubscribe">
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

      <!-- No providers configured -->
      <div v-if="!hasWebProviders && !isGooglePlayEnabled" class="billing-page__subscribe-card">
        <div class="billing-page__disabled" style="padding: 2rem; text-align: center;">
          <CIcon icon="credit-card-off" :size="40" class="billing-page__disabled-icon" />
          <h3 class="billing-page__disabled-title">{{ $t('js.billing.no_providers_title') }}</h3>
          <p class="billing-page__disabled-description">{{ $t('js.billing.no_providers_description') }}</p>
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

        <!-- Primary CTA -->
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
      </div>

      <!-- Google Play section — mobile only -->
      <div v-if="isGooglePlayEnabled" class="billing-page__mobile-section" :class="{ 'billing-page__mobile-section--standalone': !hasWebProviders }">
        <div class="billing-page__mobile-icon">
          <CIcon icon="smartphone" :size="32" />
        </div>
        <div class="billing-page__mobile-content">
          <h3 class="billing-page__mobile-title">{{ $t('js.billing.mobile_title') }}</h3>
          <p class="billing-page__mobile-description">{{ $t('js.billing.mobile_description') }}</p>
          <div class="billing-page__store-links">
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
import { ref, computed, watch, onMounted, onBeforeUnmount, inject } from 'vue';
import { useHead } from 'unhead';
import { ajax } from '../../lib/Ajax';
import CIcon from '@/components/c-icon.vue';
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
const selectedProviderKey = ref('');
const planData = ref(null);
const isFetchingPlan = ref(false);

const SiteSettings = inject('SiteSettings');
const currentUser = inject('currentUser');

// ─── Computed (from store) ────────────────────────────────────────────────────
const subscription = computed(() => subscriptionStore.subscription);
const payments = computed(() => subscriptionStore.payments);
const isSyncing = computed(() => subscriptionStore.isSyncing);
const enabledProviders = computed(() => subscriptionStore.enabledProviders);
const geoData = computed(() => subscriptionStore.geoData);

const isCancelled = computed(() => subscription.value?.status === 'cancelled');

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
  if (status === 'active') return 'active';
  if (status === 'pending') return 'pending';
  if (status === 'cancelled') return 'cancelled';
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
  return status === 'active' && !isCancelled.value;
});

const canSubscribe = computed(() => {
  if (!subscription.value) return true;
  const status = (subscription.value.status || '').toLowerCase();
  const isInactiveStatus = ['cancelled', 'expired'].includes(status);
  let isExpired = false;
  if (subscription.value.access_until) {
    const endDate = new Date(subscription.value.access_until);
    isExpired = endDate < new Date();
  }
  return isInactiveStatus || isExpired;
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

// Provider logic
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

const alternativeProviders = computed(() =>
  enabledProviders.value.filter(p =>
    p.key !== activeProviderKey.value && p.key !== 'google_play'
  )
);

const hasWebProviders = computed(() =>
  enabledProviders.value.some(p => p.key !== 'google_play')
);

const isGooglePlayEnabled = computed(() =>
  enabledProviders.value.some(p => p.key === 'google_play')
);

const googlePlayUrl = computed(() => SiteSettings?.google_play_store_url || '#');

const isAwaitingActivation = computed(() => returnedFromCheckout.value && !subscription.value);

// ─── Helpers ──────────────────────────────────────────────────────────────────
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
    const checkoutUrl = data?.data?.checkout_url;

    if (!checkoutUrl) {
      checkoutError.value = `Could not obtain checkout URL for ${providerProfile.value.displayName}.`;
      return;
    }

    window.location.href = checkoutUrl;
  } catch (error) {
    console.error('Error creating subscription:', error);
    checkoutError.value = error?.response?.data?.error || 'Could not start subscription. Please try again.';
  } finally {
    isCreatingCheckout.value = false;
    selectedCheckoutMode.value = null;
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
  const endDate = subscription.value?.access_until
    ? formatDate(subscription.value.access_until)
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
  subscriptionStore.subscription = null;
};

const switchProvider = (key) => {
  selectedProviderKey.value = key;
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
  if (newKey && newKey !== 'google_play') {
    fetchPlanForProvider(newKey);
  }
});

// ─── Focus listener ───────────────────────────────────────────────────────────
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

    if (activeProviderKey.value && activeProviderKey.value !== 'google_play') {
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
