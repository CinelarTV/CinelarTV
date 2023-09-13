/* This is a Plugin API for CinelarTV, to extend the functionality of the front-end. */

// Path: app/assets/javascripts/cinelartv/lib/plugin-api.js

import { useGlobalStore } from "../store/global";
const globalStore = useGlobalStore();

class PluginAPI {
    constructor(version) {
        this.version = version;
    }

    addGlobalBanner(banner) {
        if (!banner.id || !banner.content || !banner.show) {
            throw "Banner must have an id, content and show properties";
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
}

export default PluginAPI;
