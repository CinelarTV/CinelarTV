// store/icons.js

import { defineStore } from 'pinia'
import { generateSpriteSheet } from '../lib/IconLibrary'


export const useIconsStore = defineStore('icons', {
    state: () => ({
        icons: [],
    }),
    actions: {
        addIcon(icon) {
            if(this.icons.find(i => i.id === icon.id)) {
                return // Icon already exists
            }
            this.icons.push(icon)
            generateSpriteSheet()
        },
        // Otras acciones relacionadas con el estado global
    },
})
