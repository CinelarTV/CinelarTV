import { defineStore } from 'pinia';
import { ajax } from '../../lib/Ajax';

interface GeoData {
  country_code: string | null;
  country_name: string | null;
  recommended_provider: string | null;
}

interface SubscriptionState {
  subscription: Record<string, any> | null;
  payments: Record<string, any>[];
  geoData: GeoData;
  enabledProviders: { key: string; label: string }[];
  isLoading: boolean;
  isSyncing: boolean;
}

export const useSubscriptionStore = defineStore('subscription', {
  state: (): SubscriptionState => ({
    subscription: null,
    payments: [],
    geoData: {
      country_code: null,
      country_name: null,
      recommended_provider: null,
    },
    enabledProviders: [],
    isLoading: false,
    isSyncing: false,
  }),

  getters: {
    isActive: (state): boolean => {
      if (!state.subscription) return false;
      const status = (state.subscription.status || '').toLowerCase();
      if (['active', 'approved'].includes(status)) return true;
      if (state.subscription.ends_at && new Date(state.subscription.ends_at) > new Date()) return true;
      if (state.subscription.granted_until && new Date(state.subscription.granted_until) > new Date()) return true;
      return false;
    },

    isCancelled: (state): boolean => {
      return state.subscription?.cancelled === true;
    },

    daysUntilExpiry: (state): number | null => {
      if (!state.subscription?.ends_at) return null;
      const diff = new Date(state.subscription.ends_at).getTime() - Date.now();
      return Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24)));
    },

    hasActiveSubscription: (state): boolean => {
      return state.subscription !== null && state.subscription !== undefined;
    },
  },

  actions: {
    async fetchBillingData(): Promise<void> {
      this.isLoading = true;
      try {
        const { data } = await ajax.get('/account/billing.json');
        this.subscription = data?.data?.[0] || null;
        this.payments = data?.payments || [];
        this.geoData = data?.geo || {
          country_code: null,
          country_name: null,
          recommended_provider: null,
        };
        this.enabledProviders = data?.enabled_providers || [];
      } finally {
        this.isLoading = false;
      }
    },

    async sync(): Promise<void> {
      this.isSyncing = true;
      try {
        const { data } = await ajax.post('/account/billing/sync.json', {});
        this.subscription = data?.data || this.subscription;
      } finally {
        this.isSyncing = false;
      }
    },

    async cancel(): Promise<void> {
      await ajax.delete('/account/billing/subscribe.json');
      await this.fetchBillingData();
    },

    refreshCurrentUser(currentUser: Record<string, any> | null): void {
      if (currentUser) {
        currentUser.is_subscribed = this.isActive;
      }
    },
  },
});
