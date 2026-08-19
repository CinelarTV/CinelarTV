// store/icons.js
import { defineStore } from 'pinia'
import { generateSpriteSheet } from '../lib/IconLibrary'

export const useIconsStore = defineStore('icons', {
    state: () => ({
        icons: new Set(),
    }),
    actions: {
        /**
         * @deprecated Use register_svg_icon in plugin.rb instead.
         * This method will be removed in CinelarTV 2.0.0.
         */
        addIcon(icon) {
            console.warn(
                '[iconsStore] addIcon is deprecated. ' +
                'Register icons server-side via register_svg_icon in your plugin.rb file. ' +
                'This method will be removed in CinelarTV 2.0.0.'
            );
            if (this.icons.has(icon)) return
            this.icons.add(icon)
            generateSpriteSheet()
        },
    },
})
