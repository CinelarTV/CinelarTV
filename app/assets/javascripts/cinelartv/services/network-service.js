import { defineStore } from 'pinia';

export const useNetworkService = defineStore('network', {
  state: () => ({
    isOnline: navigator.onLine,
  }),
  actions: {
    setIsOnline(isOnline) {
      this.isOnline = isOnline;
    },
    listenStatusChange() {
      window.addEventListener('online', () => {
        this.setIsOnline(true);
      });

      window.addEventListener('offline', () => {
        this.setIsOnline(false);
      });
    },
  },
  getters: {
    onlineStatus() {
      return this.isOnline;
    },
  },
});

