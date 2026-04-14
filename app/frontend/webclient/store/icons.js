// store/icons.js
import { defineStore } from 'pinia'
import { generateSpriteSheet } from '../lib/IconLibrary'

export const useIconsStore = defineStore('icons', {
    state: () => ({
        icons: new Set(),
    }),
    actions: {
        addIcon(icon) {
            if (this.icons.has(icon)) return
            this.icons.add(icon)
            generateSpriteSheet()
        },
    },
})