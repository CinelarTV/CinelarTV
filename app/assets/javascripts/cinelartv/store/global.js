import { defineStore } from 'pinia'

export const useGlobalStore = defineStore('global', {
    state: () => ({
        banners: [],
    }),
    actions: {
        addBanner(banner) {
            this.banners.push(banner)
        },
        // Otras acciones relacionadas con el estado global
    },
})