import I18n from 'i18n-js'
try {
    await import('../i18n/translations')
} catch (error) {
    console.warn("No translations found")
}

import { useSiteSettings } from '../app/services/site-settings'
import { PiniaStore } from '../app/lib/Pinia'
const { siteSettings } = useSiteSettings(PiniaStore)

// TODO: Locale should be set by the user using preferences
I18n.locale = siteSettings?.default_locale
I18n.defaultLocale = 'en'
I18n.fallbacks = true

window.I18n = I18n

export default {
    // Provide a global method to translate strings
    install: (app) => {
        app.config.globalProperties.$t = I18n.t.bind(I18n)
        app.provide('I18n', I18n)
    }
}