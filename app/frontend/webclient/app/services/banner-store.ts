import { defineStore } from 'pinia'

export interface Banner {
    id: string;
    show: boolean;
    content?: string | null;
    customHtml?: string;
    css?: string;
    dismissable?: boolean;
    dismiss_text?: string;
    dismiss_callback?: () => void;
    icon?: string;
}

export const useBanners = defineStore('banners', {
    state: () => ({
        banners: [] as Banner[],
    }),
    getters: {
        findBanner: (state) => (bannerId: string): Banner | undefined => {
            return state.banners.find((b) => b.id === bannerId)
        },
        visibleBanners: (state): Banner[] => {
            return state.banners.filter((b) => b.show)
        },
    },
    actions: {
        addBanner(banner: Banner): void {
            if (this.banners.some((b) => b.id === banner.id)) {
                console.warn(`Banner "${banner.id}" already exists. Use updateBanner to modify it.`)
                return
            }
            this.banners.push(banner)
        },
        removeBanner(bannerId: string): void {
            const index = this.banners.findIndex((b) => b.id === bannerId)
            if (index !== -1) {
                this.banners.splice(index, 1)
            }
        },
        updateBanner(bannerId: string, payload: Partial<Omit<Banner, 'id'>>): void {
            const index = this.banners.findIndex((b) => b.id === bannerId)
            if (index !== -1) {
                this.banners[index] = { ...this.banners[index], ...payload }
            } else {
                console.warn(`Banner "${bannerId}" not found.`)
            }
        },
        upsertBanner(banner: Banner): void {
            const index = this.banners.findIndex((b) => b.id === banner.id)
            if (index !== -1) {
                this.banners[index] = { ...this.banners[index], ...banner }
            } else {
                this.banners.push(banner)
            }
        },
    },
})