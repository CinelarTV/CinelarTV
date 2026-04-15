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
        <button class="billing-page__btn" @click="manageSubscription">
          <CIcon icon="external-link" :size="18" />
          Manage Payment Method
        </button>
        <button class="billing-page__btn billing-page__btn--danger" @click="cancelSubscription" v-if="canCancel">
          <CIcon icon="x-circle" :size="18" />
          Cancel Subscription
        </button>
      </div>
    </div>

    <!-- No subscription -->
    <div v-else class="billing-page__subscribe">
      <div class="billing-page__subscribe-card">
        <CIcon icon="credit-card" :size="56" class="billing-page__subscribe-icon" />
        <h2 class="billing-page__subscribe-title">No Active Subscription</h2>
        <p class="billing-page__subscribe-description">
          Subscribe now to access premium features and content
        </p>
        <button class="billing-page__btn billing-page__btn--primary billing-page__btn--large"
          @click="createSubscription" :disabled="isCreatingCheckout">
          <CIcon :icon="isCreatingCheckout ? 'loader' : 'arrow-right'" :size="20"
            :class="{ 'billing-page__btn--spinning': isCreatingCheckout }" />
          {{ isCreatingCheckout ? 'Creating Checkout...' : 'Subscribe Now' }}
        </button>
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
import { ref, computed, onMounted, onBeforeUnmount, inject } from 'vue';
import { useHead } from 'unhead';
import { ajax } from '../../lib/Ajax';
import CIcon from '@/components/c-icon.vue';

const billingData = ref(null);
const subscription = ref(null);
const isCreatingCheckout = ref(false);
const checkoutError = ref('');

const SiteSettings = inject('SiteSettings');
const i18n = inject('I18n');
const currentUser = inject('currentUser');

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

const fetchBillingData = async () => {
  try {
    const { data } = await ajax.get('/account/billing.json');
    return data?.data?.[0] || null;
  } catch (error) {
    console.error('Error fetching billing data:', error);
    return null;
  }
};

const createSubscription = async () => {
  isCreatingCheckout.value = true;
  checkoutError.value = '';

  try {
    const { data } = await ajax.post('/account/billing/subscribe.json');
    const checkoutUrl = data?.data?.checkout_url || data?.data?.sandbox_checkout_url;

    if (!checkoutUrl) {
      checkoutError.value = 'Could not obtain subscription checkout URL.';
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
  // Redirect to MercadoPago subscription management if available
  if (subscription.value?.provider_subscription_id) {
    // Could open MercadoPago checkout management URL
    console.log('Manage subscription:', subscription.value.provider_subscription_id);
  }
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
  if (!provider) return 'N/A';
  return provider.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase());
};

const pollingInterval = ref(null);

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
  if (SiteSettings.enable_subscription) {
    subscription.value = await fetchBillingData();

    // If no subscription found, start polling (user might have just returned from checkout)
    if (!subscription.value) {
      startPolling();
    }
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
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.06);
  border-radius: 12px;
  text-align: center;
  max-width: 500px;
}

.billing-page__subscribe-icon {
  color: var(--c-tertiary-400, #0095d9);
  opacity: 0.6;
}

.billing-page__subscribe-title {
  font-size: 1.25rem;
  font-weight: 600;
  color: #fff;
  margin: 0;
}

.billing-page__subscribe-description {
  font-size: 0.85rem;
  color: rgba(255, 255, 255, 0.45);
  margin: 0;
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

  .billing-page__actions {
    flex-direction: column;
  }

  .billing-page__btn {
    width: 100%;
    justify-content: center;
  }
}
</style>
