/* This is a Plugin API for CinelarTV, to extend the functionality of the front-end. */

// Path: app/assets/javascripts/cinelartv/lib/plugin-api.js

import { ref, h } from "vue";
import { compile } from "vue-template-compiler";
import { useGlobalStore } from "../store/global";
import { useIconsStore } from "../store/icons";
import { currentUser, SiteSettings } from "../pre-initializers/essentials-preload";
import loadScript from './load-script'
const globalStore = useGlobalStore();
const iconsStore = useIconsStore();

class PluginAPI {
    constructor(version, vueInstance) {
        this.version = version;
        this.vueInstance = vueInstance;
    }

    currentInstance() {
        return this.vueInstance;
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

    replaceIcon(iconName, svgIcon) {
        let iconSheet = document.getElementById('cinelar-icon-sheet');
        if (!iconSheet) {
            throw "CinelarTV icon sheet not found";
        }

        let svgSheet = iconSheet.querySelector('svg');
        if (!svgSheet) {
            throw "CinelarTV icon sheet not found";
        }

        let iconSymbol = svgSheet.querySelector(`symbol#${iconName}`);
        if (!iconSymbol) {
            throw `CinelarTV icon ${iconName} not found`;
        }

        // Replace the symbol with the new icon
        iconSymbol.innerHTML = svgIcon;
    }

    addIcon(iconName, svgIcon = null) {
        if (!svgIcon) {
            // If no SVG icon is provided, we are trying to add an icon from the icon library
            iconsStore.addIcon(iconName);
            return;
        }

        let iconSheet = document.getElementById('cinelar-icon-sheet');
        if (!iconSheet) {
            throw "CinelarTV icon sheet not found";
        }

        let svgSheet = iconSheet.querySelector('svg');
        if (!svgSheet) {
            throw "CinelarTV icon sheet not found";
        }

        // Create the symbol
        let symbol = document.createElementNS('http://www.w3.org/2000/svg', 'symbol');
        symbol.id = iconName;
        symbol.innerHTML = svgIcon;

        // Add the symbol to the sheet

        svgSheet.appendChild(symbol);


    } 
    
    loadScript = loadScript;
}

export default PluginAPI;
