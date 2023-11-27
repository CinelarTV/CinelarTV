/* This is a Plugin API for CinelarTV, to extend the functionality of the front-end. */

// Path: app/assets/javascripts/cinelartv/lib/plugin-api.js

import { ref, h } from "vue";
import { compile } from "vue-template-compiler";
import { useGlobalStore } from "../store/global";
import { useIconsStore } from "../store/icons";
import loadScript from './load-script'
import deprecated from "./deprecated";
import { useSiteSettings } from "../app/services/site-settings";
import { useCurrentUser } from "../app/services/current-user";
import { Banner, useBanners } from "../app/services/banner-store";
const iconsStore = useIconsStore();
const { currentUser } = useCurrentUser();
const { siteSettings } = useSiteSettings();

let instance = null;

class PluginAPI {
    public version: string;
    public vueInstance: any;
    constructor(version: string, vueInstance: any) {
        
        if (!instance) {
            this.version = version;
            this.vueInstance = vueInstance;
            instance = this;
        } else {
            return instance;
        }
    }

    public static getInstance() {
        return instance || null;
    }

    addGlobalBanner(banner: Banner) {
        deprecated("addGlobalBanner is deprecated. Use addGlobalNotice instead.", {
            deprecatedFunction: "addGlobalBanner",
            since: "1.0.0",
            dropFrom: "1.1.0"
        });

        this.addGlobalNotice(banner);
    }

    addGlobalNotice(notice: Banner) {
        const { addBanner, findBanner } = useBanners();
        console.log(notice)
        if (!notice.id || notice.show === undefined) {
            console.error("Banner must have an id and show properties");
        }

        if (notice.content && notice?.customHtml) {
            // Prioritize custom HTML over content
            notice.content = null;
        }

        if (notice.css) {
            const styleId = `notice-${notice.id}-css`;
            let styleTag = document.getElementById(styleId);

            if (!styleTag) {
                styleTag = document.createElement('style');
                styleTag.id = styleId;

                const assetsStylesheets = document.querySelector('cinelar-assets-stylesheets');

                if (!assetsStylesheets) {
                    console.error("Unable to find <cinelar-assets-stylesheets> tag");
                    return;
                }

                assetsStylesheets.appendChild(styleTag);
            }
            styleTag.innerHTML = notice.css;
        }



        // If banner already exists, update it, otherwise add it
        let existingNotice = findBanner(notice.id);
        if (existingNotice) {
            existingNotice = notice;
        }
        else {
            addBanner(notice);
        }
    }

    removeGlobalBanner(id) {
        deprecated("removeGlobalBanner is deprecated. Use removeGlobalNotice instead.", {
            deprecatedFunction: "removeGlobalBanner",
            since: "1.0.0",
            dropFrom: "1.1.0"
        });

        this.removeGlobalNotice(id);
    }

    removeGlobalNotice(id) {
        const { removeBanner } = useBanners();
        removeBanner(id);
    }


    getCurrentUser() {
        return currentUser;
    }

    getSiteSettings() {
        return siteSettings;
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

    getCustomData() {
        try {
            let customData = JSON.parse(siteSettings.api_custom_data);
            return customData;
        } catch (error) {
            console.error("Unable to parse custom data");
        }
    }

    loadScript = loadScript;
}

export default PluginAPI;