import { defineStore } from 'pinia';
import { PiniaStore } from "../lib/Pinia";

interface SiteSettingsState {
  siteSettings: any;
}

export const useSiteSettings = defineStore('siteSettings', {
  state: (): SiteSettingsState => ({
    siteSettings: {},
  }),

  actions: {
    setSiteSettings(settings: any) {
      this.siteSettings = settings;
    },
    async fetchSiteSettings() {
      // Ajusta la URL si es necesario
      const res = await fetch('/site-settings.json');
      if (res.ok) {
        const data = await res.json();
        this.setSiteSettings(data);
      }
    },
    subscribeToMessageBus() {
      if (typeof window !== 'undefined' && (window as any).MessageBus) {
        (window as any).MessageBus.subscribe('/site-settings', async () => {
          await this.fetchSiteSettings();
        });
      }
    },
  },
});

// Suscribirse automáticamente si se importa el store
const store = useSiteSettings(PiniaStore);
if (typeof window !== 'undefined' && (window as any).MessageBus) {
  store.subscribeToMessageBus();
}
