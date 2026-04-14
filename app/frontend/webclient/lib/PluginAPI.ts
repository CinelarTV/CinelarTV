/* This is a Plugin API for CinelarTV, to extend the functionality of the front-end. */

// Path: app/assets/javascripts/cinelartv/lib/plugin-api.js

import { ref } from "vue";
import { useIconsStore } from "../store/icons";
import loadScript from "./load-script";
import deprecated from "./deprecated";
import { useSiteSettings } from "../app/services/site-settings";
import { useCurrentUser } from "../app/services/current-user";
import { Banner, useBanners } from "../app/services/banner-store";
import { PLUGIN_OUTLET_NAMES, PluginOutletName } from "@/stores/pluginOutletNames";
import { registerPluginOutlet } from "@/components/PluginOutlet";

// ─── Tipos ────────────────────────────────────────────────────────────────────

type SvgIcon = string | null;

// ─── Singleton ────────────────────────────────────────────────────────────────

let instance: PluginAPI | null = null;

// ─── Helpers internos ─────────────────────────────────────────────────────────

/** Devuelve el SVG sheet o lanza un error descriptivo. */
function getIconSheet(): SVGElement {
    const iconSheet = document.getElementById("cinelar-icon-sheet");
    const svgSheet = iconSheet?.querySelector("svg");

    if (!iconSheet || !svgSheet) {
        throw new Error("CinelarTV icon sheet not found");
    }

    return svgSheet as unknown as SVGElement;
}

// ─── Clase ────────────────────────────────────────────────────────────────────

class PluginAPI {
    public readonly version: string;
    public readonly vueInstance: any;

    /** Cache del custom data ya parseado. */
    private _customDataCache: Record<string, unknown> | null = null;

    constructor(version: string, vueInstance: any) {
        if (instance) return instance;

        this.version = version;
        this.vueInstance = vueInstance;
        instance = this;
    }

    static getInstance(): PluginAPI | null {
        return instance;
    }

    // ── Outlets ───────────────────────────────────────────────────────────────

    addOutletComponent(outlet: PluginOutletName, component: any): void {
        if (!PLUGIN_OUTLET_NAMES.includes(outlet)) {
            console.warn(`⚠️ Outlet "${outlet}" not found`);
            return;
        }

        registerPluginOutlet(outlet, component);
    }

    // ── Banners / Notices ─────────────────────────────────────────────────────

    /** @deprecated Use addGlobalNotice instead. */
    addGlobalBanner(banner: Banner): void {
        deprecated("addGlobalBanner is deprecated. Use addGlobalNotice instead.", {
            deprecatedFunction: "addGlobalBanner",
            since: "1.0.0",
            dropFrom: "1.1.0",
        });
        this.addGlobalNotice(banner);
    }

    addGlobalNotice(notice: Banner): void {
        if (!notice.id || notice.show === undefined) {
            console.error("Banner must have an id and show properties");
            return;
        }

        // Priorizar customHtml sobre content
        if (notice.content && notice.customHtml) {
            notice = { ...notice, content: undefined };
        }

        // Inyectar CSS del banner si se provee
        if (notice.css) {
            this._injectNoticeCss(notice.id, notice.css);
        }

        const { addBanner, findBanner, updateBanner } = useBanners();
        const existing = findBanner(notice.id);

        // FIX: antes se reasignaba la variable local en vez de llamar al store
        if (existing) {
            updateBanner(notice.id, notice);
        } else {
            addBanner(notice);
        }
    }

    /** @deprecated Use removeGlobalNotice instead. */
    removeGlobalBanner(id: string): void {
        deprecated("removeGlobalBanner is deprecated. Use removeGlobalNotice instead.", {
            deprecatedFunction: "removeGlobalBanner",
            since: "1.0.0",
            dropFrom: "1.1.0",
        });
        this.removeGlobalNotice(id);
    }

    removeGlobalNotice(id: string): void {
        const { removeBanner } = useBanners();
        removeBanner(id);
    }

    // ── Íconos ────────────────────────────────────────────────────────────────

    replaceIcon(iconName: string, svgIcon: string): void {
        const svgSheet = getIconSheet();
        const symbol = svgSheet.querySelector(`symbol#${iconName}`);

        if (!symbol) {
            throw new Error(`CinelarTV icon "${iconName}" not found`);
        }

        symbol.innerHTML = svgIcon;
    }

    addIcon(iconName: string, svgIcon: SvgIcon = null): void {
        if (!svgIcon) {
            useIconsStore().addIcon(iconName);
            return;
        }

        const svgSheet = getIconSheet();
        const symbol = document.createElementNS("http://www.w3.org/2000/svg", "symbol");
        symbol.id = iconName;
        symbol.innerHTML = svgIcon;
        svgSheet.appendChild(symbol);
    }

    // ── Usuario / Settings ────────────────────────────────────────────────────

    getCurrentUser() {
        return useCurrentUser().currentUser;
    }

    getSiteSettings() {
        return useSiteSettings().siteSettings;
    }

    getCustomData(): Record<string, unknown> | null {
        if (this._customDataCache) return this._customDataCache;

        try {
            const raw = useSiteSettings().siteSettings.api_custom_data;
            this._customDataCache = JSON.parse(raw);
            return this._customDataCache;
        } catch {
            console.error("Unable to parse custom data");
            return null;
        }
    }

    // ── Vue helpers ───────────────────────────────────────────────────────────

    ref = ref;
    loadScript = loadScript;

    // ── Privados ──────────────────────────────────────────────────────────────

    private _injectNoticeCss(id: string, css: string): void {
        const styleId = `notice-${id}-css`;

        let styleTag = document.getElementById(styleId) as HTMLStyleElement | null;

        if (!styleTag) {
            const container = document.querySelector("cinelar-assets-stylesheets");
            if (!container) {
                console.error("Unable to find <cinelar-assets-stylesheets> tag");
                return;
            }

            styleTag = document.createElement("style");
            styleTag.id = styleId;
            container.appendChild(styleTag);
        }

        styleTag.innerHTML = css;
    }
}

export default PluginAPI;