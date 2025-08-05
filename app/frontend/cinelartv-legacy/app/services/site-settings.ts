import { defineStore } from 'pinia';

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
  },
});
