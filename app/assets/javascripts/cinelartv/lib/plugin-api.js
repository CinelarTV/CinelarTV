/* This is a Plugin API for CinelarTV, to extend the functionality of the front-end. */

// Path: app/assets/javascripts/cinelartv/lib/plugin-api.js

import { ref } from "vue";
import { useGlobalStore } from "../store/global";
import { currentUser, SiteSettings } from "../pre-initializers/essentials-preload";
const globalStore = useGlobalStore();

class PluginAPI {
    constructor(version) {
        this.version = version;
    }

    addGlobalBanner(banner) {
        if (!banner.id || !banner.show) {
            throw "Banner must have an id and show properties";
        }

        if (banner.content && banner?.custom_html) {
            // Prioritize custom HTML over content
            banner.content = null;
        }


        // If banner already exists, update it, otherwise add it
        let existingBanner = globalStore.banners.find(b => b.id === banner.id);
        if (existingBanner) {
            existingBanner = banner;
        }
        else {
            globalStore.banners.push(banner);
        }
    }

    removeGlobalBanner(id) {
        globalStore.banners = globalStore.banners.filter(banner => banner.id !== id);
    }

    getCurrentUser() {
        return currentUser;
    }

    getSiteSettings() {
        return SiteSettings;
    }

    ref(value) {
        return ref(value);
    }

}

export default PluginAPI;
