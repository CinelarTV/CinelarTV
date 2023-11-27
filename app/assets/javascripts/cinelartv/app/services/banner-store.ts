import { defineStore } from 'pinia'

export interface Banner {
    id: string;
    show: boolean;
    content?: string;
    customHtml?: string;
    css?: string;
    dismissable?: boolean;
    dismiss_text?: string;
    dismiss_callback?: Function;
    icon?: string;
}

export const useBanners = defineStore('global', {
    state: () => ({
        banners: [] as Banner[],
    }),
    actions: {
        addBanner(banner: Banner) {
            this.banners.push(banner)
        },
        removeBanner(bannerId: string) {
            this.banners = this.banners.filter((b: { id: string; }) => b.id !== bannerId)
        },
        findBanner(bannerId: string) {
            return this.banners.find((b: { id: string; }) => b.id === bannerId)
        },
    },
})