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
      <CIcon icon="credit-card" :size="48" class="billing-page__disabled-icon" />
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

    <!-- Awaiting activation (returned from checkout with polling) -->
    <div v-else-if="isAwaitingActivation" class="billing-page__pending">
      <div class="billing-page__pending-card">
        <div class="billing-page__pending-pulse" />
        <h2 class="billing-page__pending-title">{{ $t('js.billing.activation_in_progress') }}</h2>
        <p class="billing-page__pending-description">
          {{ $t('js.billing.activation_waiting_provider', { provider: activeProviderProfile.displayName }) }}
        </p>
        <div class="billing-page__pending-actions">
          <BillingActionButton icon="refresh-cw" :loading="isSyncing" variant="primary" @click="manualSync">
            {{ isSyncing ? $t('js.billing.syncing') : $t('js.billing.awaiting_sync') }}
          </BillingActionButton>
        </div>
        <p class="billing-page__pending-hint">
          {{ $t('js.billing.awaiting_hint') }}
        </p>
      </div>
    </div>

    <!-- Pending stuck (subscription is pending but user didn't come from checkout) -->
    <div v-else-if="isPendingStuck" class="billing-page__pending">
      <div class="billing-page__pending-card">
        <div class="billing-page__pending-pulse" />
        <h2 class="billing-page__pending-title">{{ $t('js.billing.activation_in_progress') }}</h2>
        <p class="billing-page__pending-description">
          {{ $t('js.billing.activation_waiting_provider', { provider: activeProviderProfile.displayName }) }}
        </p>
        <div class="billing-page__pending-actions">
          <BillingActionButton icon="refresh-cw" :loading="isSyncing" variant="primary" @click="manualSync">
            {{ isSyncing ? $t('js.billing.syncing') : $t('js.billing.awaiting_sync') }}
          </BillingActionButton>
        </div>
      </div>
    </div>

    <!-- Active / cancelled subscription -->
    <div v-else-if="subscription && !canSubscribe" class="billing-page__content">
      <div class="billing-plan-card" :class="{ 'billing-plan-card--cancelled': isCancelled }">
        <!-- Status badge & Provider tag -->
        <div class="billing-plan-card__status-row">
          <span class="billing-plan-card__badge" :class="`billing-plan-card__badge--${subscriptionStatusClass}`">
            <CIcon :icon="subscriptionStatusIcon" :size="14" />
            {{ subscription.status_formatted || subscription.status }}
          </span>
          <span v-if="subscription.provider" class="billing-plan-card__provider-tag">
            <CIcon icon="credit-card" :size="12" />
            {{ formatProvider(subscription.provider) }}
          </span>
        </div>

        <!-- Plan Header -->
        <div class="billing-plan-card__header-info">
          <h2 class="billing-plan-card__title">CinelarTV+</h2>
          <p class="billing-plan-card__variant">{{ $t('js.billing.active_plan') }}</p>
        </div>

        <!-- Cancellation Notice Banner -->
        <div v-if="isCancelled" class="billing-plan-card__cancellation-notice">
          <CIcon icon="alert-circle" :size="18" class="billing-plan-card__cancellation-icon" />
          <div class="billing-plan-card__cancellation-text">
            <span>{{ $t('js.billing.cancelled_notice', { date: formatDate(subscription.ends_at) }) }}</span>
          </div>
        </div>

        <!-- Details Grid -->
        <div class="billing-plan-card__details">
          <div v-if="!isCancelled && subscription.renews_at" class="billing-plan-detail">
            <span class="billing-plan-detail__label">{{ $t('js.billing.renews_at') }}</span>
            <span class="billing-plan-detail__value">
              <CIcon icon="calendar" :size="14" class="billing-plan-detail__icon" />
              {{ formatDate(subscription.renews_at) }}
            </span>
          </div>

          <div v-if="isCancelled && subscription.ends_at" class="billing-plan-detail">
            <span class="billing-plan-detail__label">{{ $t('js.billing.ends_at') }}</span>
            <span class="billing-plan-detail__value billing-plan-detail__value--warning">
              <CIcon icon="clock" :size="14" class="billing-plan-detail__icon" />
              {{ formatDate(subscription.ends_at) }}
            </span>
          </div>

          <div class="billing-plan-detail">
            <span class="billing-plan-detail__label">{{ $t('js.billing.billing_email') }}</span>
            <span class="billing-plan-detail__value">
              <CIcon icon="mail" :size="14" class="billing-plan-detail__icon" />
              {{ currentUser?.email || '—' }}
            </span>
          </div>

          <div v-if="lastPaymentInfo" class="billing-plan-detail">
            <span class="billing-plan-detail__label">{{ $t('js.billing.last_payment') }}</span>
            <span class="billing-plan-detail__value">
              <CIcon icon="check" :size="14" class="billing-plan-detail__icon" />
              {{ lastPaymentInfo }}
            </span>
          </div>
        </div>

        <!-- Actions Toolbar -->
        <div class="billing-plan-card__actions">
          <BillingActionButton icon="refresh-cw" :loading="isSyncing" variant="secondary" @click="manualSync">
            {{ isSyncing ? $t('js.billing.syncing') : $t('js.billing.sync') }}
          </BillingActionButton>

          <BillingActionButton
            v-if="hasManagementUrl"
            icon="arrow-right"
            variant="secondary"
            @click="manageSubscription"
          >
            {{ $t('js.billing.direct_management', { provider: formatProvider(subscription.provider) }) }}
          </BillingActionButton>

          <BillingActionButton v-if="isCancelled" icon="refresh-cw" variant="primary" @click="resubscribe">
            {{ $t('js.billing.resubscribe') }}
          </BillingActionButton>

          <BillingActionButton v-else-if="canCancel" icon="x" variant="danger" @click="openCancelModal">
            {{ $t('js.billing.cancel') }}
          </BillingActionButton>
        </div>
      </div>
    </div>

    <!-- No active subscription — Subscribe Flow (Netflix style) -->
    <div v-else class="billing-page__subscribe">
      <!-- Web providers checkout card -->
      <div v-if="hasWebProviders" class="billing-page__subscribe-card">
        <!-- Membership Badge & Title -->
        <div class="billing-page__subscribe-hero">
          <span class="billing-page__premium-badge">
            <CIcon icon="sparkles" :size="14" />
            CinelarTV+
          </span>
        </div>

        <!-- Price Hero -->
        <div v-if="isFetchingPlan" class="billing-page__price-hero billing-page__price-hero--loading">
          <CIcon icon="loader" :size="20" class="animate-spin" />
        </div>
        <div v-else-if="planData" class="billing-page__price-hero">
          <span class="billing-page__price-amount">{{ planFormattedAmount }}</span>
          <span class="billing-page__price-period">/{{ planFrequencyText }}</span>
        </div>
        <div v-else class="billing-page__price-hero billing-page__price-hero--unavailable">
          <span class="billing-page__price-amount">{{ $t('js.billing.price_unavailable') }}</span>
        </div>

        <!-- Benefits List -->
        <ul class="billing-page__benefits">
          <li class="billing-page__benefit-item">
            <CIcon icon="check" :size="16" class="billing-page__benefit-icon" />
            <span>{{ $t('js.billing.benefits.no_ads') }}</span>
          </li>
          <li class="billing-page__benefit-item">
            <CIcon icon="check" :size="16" class="billing-page__benefit-icon" />
            <span>{{ $t('js.billing.benefits.early_premiere') }}</span>
          </li>
          <li class="billing-page__benefit-item">
            <CIcon icon="check" :size="16" class="billing-page__benefit-icon" />
            <span>{{ $t('js.billing.benefits.quality') }}</span>
          </li>
          <li class="billing-page__benefit-item">
            <CIcon icon="check" :size="16" class="billing-page__benefit-icon" />
            <span>{{ $t('js.billing.benefits.cancel_anytime') }}</span>
          </li>
        </ul>

        <!-- Provider Selection Cards (Netflix / Prime style) -->
        <div v-if="availableWebProviders.length > 0" class="billing-page__provider-selection">
          <label class="billing-page__provider-selection-title">
            {{ $t('js.billing.choose_payment_method') }}
          </label>
          <p class="billing-page__provider-selection-desc">
            {{ $t('js.billing.choose_payment_method_desc') }}
          </p>

          <div class="billing-page__provider-grid">
            <div
              v-for="prov in availableWebProviders"
              :key="prov.key"
              class="billing-provider-card"
              :class="{ 'billing-provider-card--selected': activeProviderKey === prov.key }"
              @click="switchProvider(prov.key)"
            >
              <div class="billing-provider-card__header">
                <div class="billing-provider-card__radio">
                  <div v-if="activeProviderKey === prov.key" class="billing-provider-card__radio-dot" />
                </div>
                <span class="billing-provider-card__name">{{ prov.profile.displayName }}</span>
              </div>
              <p class="billing-provider-card__subtitle">{{ prov.profile.subtitle }}</p>
            </div>
          </div>
        </div>

        <!-- Primary Checkout CTA -->
        <div class="billing-page__cta-wrapper">
          <BillingActionButton
            id="billing-subscribe-btn"
            large
            icon="arrow-right"
            loading-icon="loader"
            variant="primary"
            :loading="isCreatingCheckout && selectedCheckoutMode === 'redirect'"
            :disabled="isCreatingCheckout"
            @click="createSubscription('redirect')"
          >
            {{ isCreatingCheckout && selectedCheckoutMode === 'redirect'
              ? activeProviderProfile.checkoutLoadingCta
              : planPrice
                ? $t('js.billing.subscribe_cta', { provider: activeProviderProfile.displayName, price: planPrice })
                : $t('js.billing.subscribe_cta_no_price', { provider: activeProviderProfile.displayName }) }}
          </BillingActionButton>

          <!-- Security Badge -->
          <div class="billing-page__security-notice">
            <CIcon icon="lock" :size="13" />
            <span>{{ $t('js.billing.encrypted_badge') }}</span>
          </div>
        </div>
      </div>

      <!-- No providers configured alert -->
      <div v-else-if="!isGooglePlayEnabled" class="billing-page__subscribe-card">
        <div class="billing-page__disabled" style="padding: 2rem; text-align: center;">
          <CIcon icon="credit-card" :size="40" class="billing-page__disabled-icon" />
          <h3 class="billing-page__disabled-title">{{ $t('js.billing.no_providers_title') }}</h3>
          <p class="billing-page__disabled-description">{{ $t('js.billing.no_providers_description') }}</p>
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
              <img src="@/assets/store-badges/google-play.svg" alt="Get it on Google Play" class="billing-page__store-badge" />
            </a>
          </div>
        </div>
      </div>
    </div>

    <!-- Independent Payment History (Always accessible at bottom) -->
    <div v-if="payments && payments.length > 0" class="billing-page__history">
      <h3 class="billing-page__history-title">
        <CIcon icon="credit-card" :size="18" />
        {{ $t('js.billing.payment_history') }}
      </h3>
      <div class="billing-page__history-list">
        <div v-for="payment in payments" :key="payment.id" class="billing-page__history-item">
          <div class="billing-page__history-item-left">
            <span class="billing-page__history-date">{{ formatDate(payment.paid_at || payment.created_at) }}</span>
            <div class="billing-page__history-meta">
              <span class="billing-page__history-status" :class="`billing-page__history-status--${payment.status}`">
                {{ formatPaymentStatus(payment.status) }}
              </span>
              <span v-if="payment.provider" class="billing-page__history-provider">
                · vía {{ formatProvider(payment.provider) }}
              </span>
            </div>
          </div>
          <div class="billing-page__history-item-right">
            <span class="billing-page__history-amount">{{ formatAmount(payment.amount, payment.currency) }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Custom Cancellation Modal (Netflix Style) -->
    <CModal
      v-model="showCancelModal"
      size="md"
      :title="$t('js.billing.cancel_modal_title')"
      :subtitle="$t('js.billing.cancel_modal_subtitle')"
    >
      <div class="billing-cancel-modal">
        <p class="billing-cancel-modal__intro">
          {{ $t('js.billing.cancel_modal_benefits_header') }}
        </p>

        <ul class="billing-cancel-modal__benefits">
          <li class="billing-cancel-modal__benefit-item">
            <CIcon icon="check" :size="16" class="billing-cancel-modal__benefit-icon" />
            <span>{{ $t('js.billing.cancel_modal_benefit_1', { date: formatDate(subscription?.ends_at || subscription?.access_until) }) }}</span>
          </li>
          <li class="billing-cancel-modal__benefit-item">
            <CIcon icon="check" :size="16" class="billing-cancel-modal__benefit-icon" />
            <span>{{ $t('js.billing.cancel_modal_benefit_2') }}</span>
          </li>
          <li class="billing-cancel-modal__benefit-item">
            <CIcon icon="check" :size="16" class="billing-cancel-modal__benefit-icon" />
            <span>{{ $t('js.billing.cancel_modal_benefit_3') }}</span>
          </li>
        </ul>
      </div>

      <template #footer>
        <div class="billing-cancel-modal__footer">
          <CButton variant="secondary" @click="showCancelModal = false">
            {{ $t('js.billing.cancel_modal_keep') }}
          </CButton>
          <CButton variant="danger" :loading="isCancelling" @click="executeCancelSubscription">
            {{ isCancelling ? $t('js.billing.cancel_modal_cancelling') : $t('js.billing.cancel_modal_confirm') }}
          </CButton>
        </div>
      </template>
    </CModal>

    <!-- Error Toast Notification -->
    <div v-if="checkoutError" class="billing-page__error">
      <CIcon icon="alert-circle" :size="18" />
      <span>{{ checkoutError }}</span>
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
import CModal from '@/components/CModal.vue';
import CButton from '@/components/forms/c-button';
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
const showCancelModal = ref(false);
const isCancelling = ref(false);

const SiteSettings = inject('SiteSettings');
const currentUser = inject('currentUser');

// ─── Computed (from store) ────────────────────────────────────────────────────
const subscription = computed(() => subscriptionStore.subscription);
const payments = computed(() => subscriptionStore.payments);
const isSyncing = computed(() => subscriptionStore.isSyncing);
const enabledProviders = computed(() => subscriptionStore.enabledProviders);
const geoData = computed(() => subscriptionStore.geoData);

const isCancelled = computed(() => subscription.value?.status === 'cancelled');

const planFormattedAmount = computed(() => {
  if (!planData.value) return null;
  const amount = Number(planData.value.amount) || 0;
  const currency = (planData.value.currency || 'USD').toUpperCase();
  const locale = SiteSettings?.default_locale || 'es';
  try {
    return new Intl.NumberFormat(locale, { style: 'currency', currency, minimumFractionDigits: 2 }).format(amount);
  } catch {
    return `${currency} ${amount.toFixed(2)}`;
  }
});

const planPrice = computed(() => {
  return planFormattedAmount.value;
});

const planFrequencyText = computed(() => {
  if (!planData.value) return null;
  const freq = planData.value.frequency || 1;
  const type = planData.value.frequency_type || 'month';
  if (freq === 1) {
    const labels = { day: 'día', week: 'semana', month: 'mes', year: 'año', days: 'día', weeks: 'semana', months: 'mes', years: 'año' };
    return labels[type] || type;
  }
  const labels = { day: 'días', week: 'semanas', month: 'meses', year: 'años', days: 'días', weeks: 'semanas', months: 'meses', years: 'años' };
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
    case 'active': return 'check';
    case 'pending': return 'clock';
    case 'cancelled': return 'x';
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
  if (subscription.value.access_until) {
    const endDate = new Date(subscription.value.access_until);
    if (endDate > new Date()) return false;
  }
  const isInactiveStatus = ['cancelled', 'expired'].includes(status);
  return isInactiveStatus;
});

const hasManagementUrl = computed(() => {
  const meta = subscription.value?.metadata || {};
  return !!(
    meta.management_url
    || meta.manage_url
    || meta.customer_portal
    || meta.customer_portal_update_subscription
    || meta.update_payment_method_url
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
  const locale = SiteSettings?.default_locale || 'es';
  return `${date.toLocaleDateString(locale, { month: 'short', day: 'numeric', year: 'numeric' })}${amount}`;
});

// Provider logic
const activeProviderKey = computed(() => {
  if (subscription.value?.provider) {
    return String(subscription.value.provider).trim().toLowerCase();
  }
  if (selectedProviderKey.value) {
    return String(selectedProviderKey.value).trim().toLowerCase();
  }
  if (geoData.value.recommended_provider) {
    const recommended = String(geoData.value.recommended_provider).trim().toLowerCase();
    if (enabledProviders.value.some((p) => p.key === recommended)) return recommended;
  }
  if (SiteSettings?.subscription_provider_primary) {
    const primary = String(SiteSettings.subscription_provider_primary).trim().toLowerCase();
    if (enabledProviders.value.some((p) => p.key === primary)) return primary;
  }
  const firstWeb = enabledProviders.value.find((p) => p.key !== 'google_play');
  return firstWeb ? firstWeb.key : 'paypal';
});

const activeProviderProfile = computed(() =>
  buildBillingProviderUiProfile(activeProviderKey.value, SiteSettings)
);

const availableWebProviders = computed(() =>
  enabledProviders.value
    .filter((p) => p.key !== 'google_play')
    .map((p) => ({
      key: p.key,
      label: p.label,
      profile: buildBillingProviderUiProfile(p.key, SiteSettings),
    }))
);

const hasWebProviders = computed(() =>
  enabledProviders.value.some((p) => p.key !== 'google_play')
);

const isGooglePlayEnabled = computed(() =>
  enabledProviders.value.some((p) => p.key === 'google_play')
);

const googlePlayUrl = computed(() => SiteSettings?.google_play_store_url || '#');

const isAwaitingActivation = computed(() =>
  returnedFromCheckout.value && (!subscription.value || subscription.value.status === 'pending')
);

const isPendingStuck = computed(() =>
  subscription.value?.status === 'pending' && !returnedFromCheckout.value
);

// ─── Helpers ──────────────────────────────────────────────────────────────────
const formatDate = (value) => {
  if (!value) return '—';
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return '—';
  const locale = SiteSettings?.default_locale || 'es';
  return d.toLocaleDateString(locale, { month: 'long', day: 'numeric', year: 'numeric' });
};

const formatAmount = (amount, currency) => {
  const num = Number(amount) || 0;
  const curr = currency || 'USD';
  const locale = SiteSettings?.default_locale || 'es';
  try {
    return new Intl.NumberFormat(locale, { style: 'currency', currency: curr }).format(num);
  } catch {
    return `${num.toFixed(2)} ${curr}`;
  }
};

const formatProvider = (provider) => formatProviderLabel(provider);

const formatPaymentStatus = (status) => {
  const s = String(status || '').toLowerCase();
  if (s === 'succeeded' || s === 'approved') return 'Pagado';
  if (s === 'refunded') return 'Reembolsado';
  if (s === 'failed' || s === 'rejected') return 'Fallido';
  if (s === 'pending') return 'Pendiente';
  return status;
};

// ─── Manual sync & polling ────────────────────────────────────────────────────
let pollTimer = null;
let pollCount = 0;
const MAX_POLL_ATTEMPTS = 12;
const POLL_DELAYS = [5000, 8000, 12000, 15000, 20000, 30000];

const stopPolling = () => {
  if (pollTimer) {
    clearTimeout(pollTimer);
    pollTimer = null;
  }
  pollCount = 0;
};

const startPostCheckoutPolling = () => {
  stopPolling();
  pollCount = 0;

  const poll = async () => {
    pollCount += 1;
    try {
      await subscriptionStore.sync();
      subscriptionStore.refreshCurrentUser(currentUser);
      if (subscription.value?.status === 'active') {
        stopPolling();
        returnedFromCheckout.value = false;
        return;
      }
    } catch { /* ignore */ }

    if (pollCount < MAX_POLL_ATTEMPTS) {
      const delay = POLL_DELAYS[Math.min(pollCount - 1, POLL_DELAYS.length - 1)];
      pollTimer = setTimeout(poll, delay);
    }
  };
  poll();
};

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
    if (activeProviderKey.value) payload.provider = activeProviderKey.value;

    const { data } = await ajax.post('/account/billing/subscribe.json', payload);

    if (data?.data?.already_subscribed) {
      checkoutError.value = $t('js.billing.already_subscribed');
      return;
    }

    const checkoutUrl = data?.data?.redirect_url || data?.data?.checkout_url;

    if (!checkoutUrl) {
      checkoutError.value = `Could not obtain checkout URL for ${activeProviderProfile.value.displayName}.`;
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
  const url = meta.management_url
    || meta.manage_url
    || meta.customer_portal
    || meta.customer_portal_update_subscription
    || meta.update_payment_method_url
    || meta.portal_url
    || meta.init_point;
  if (url) window.open(url, '_blank');
};

const openCancelModal = () => {
  showCancelModal.value = true;
};

const executeCancelSubscription = async () => {
  isCancelling.value = true;
  try {
    await subscriptionStore.cancel();
    subscriptionStore.refreshCurrentUser(currentUser);
    showCancelModal.value = false;
    checkoutError.value = '';
  } catch (error) {
    checkoutError.value = error?.response?.data?.error || 'Failed to cancel subscription.';
  } finally {
    isCancelling.value = false;
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

    if (returnedFromCheckout.value) {
      startPostCheckoutPolling();
    }

    subscriptionStore.refreshCurrentUser(currentUser);
  } finally {
    isHydratingBilling.value = false;
  }
});

onBeforeUnmount(() => {
  stopPolling();
});

useHead({
  title: 'Membership',
  meta: [{ name: 'description', content: 'Manage your CinelarTV subscription and billing details.' }],
});
</script>
