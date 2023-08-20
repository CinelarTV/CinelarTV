import I18n from 'i18n-js'
try {
    require('../i18n/translations')
} catch (error) {
    console.warn("No translations found")
}

import { SiteSettings } from '../pre-initializers/essentials-preload'

I18n.locale = SiteSettings.default_locale
I18n.defaultLocale = SiteSettings.default_locale

window.I18n = I18n

export default {
    // Provide a global method to translate strings
    install: (app) => {
        app.config.globalProperties.$t = I18n.t.bind(I18n)
    }
}