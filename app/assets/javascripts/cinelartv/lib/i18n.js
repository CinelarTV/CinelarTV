import I18n from 'i18n-js'
try {
    require('../i18n/translations')
} catch (error) {
    console.warn("No translations found")
}

import { SiteSettings } from '../pre-initializers/essentials-preload'

// TODO: Locale should be set by the user using preferences
I18n.locale = SiteSettings.default_locale
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