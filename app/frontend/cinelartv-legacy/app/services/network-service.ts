import { defineStore } from 'pinia';

export const useNetworkService = defineStore('online-status', {
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
        document.body.classList.remove('cinelar-offline')
      });

      window.addEventListener('offline', () => {
        this.setIsOnline(false);
        document.body.classList.add('cinelar-offline')      
      });
    },
  },
  getters: {
    onlineStatus() {
      return this.isOnline;
    },
  },
});

