/* This is a Plugin API for CinelarTV, to extend the functionality of the front-end. */

// Path: app/assets/javascripts/cinelartv/lib/plugin-api.js

import { useGlobalStore } from "../store/global";
const globalStore = useGlobalStore();

class PluginAPI {
    constructor(version) {
        this.version = version;
    }

    addGlobalBanner(banner) {
        const { id, content, show } = banner;
        globalStore.addBanner({ id, content, show });
    }
}

export default PluginAPI;
