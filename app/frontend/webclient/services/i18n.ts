import I18n from 'i18n-js';
import '../i18n/translations.js'; // Ajusta la ruta si es necesario
import { usePreloadedStore } from "../pre-initializers/essentials-preload.js";

I18n.defaultLocale = 'en';
I18n.fallbacks = true;

export const useI18n = () => {
    const { SiteSettings, currentUser } = usePreloadedStore();
    I18n.locale = currentUser?.locale || SiteSettings?.default_locale || 'en';
    return I18n.t.bind(I18n);
};

export default I18n;
