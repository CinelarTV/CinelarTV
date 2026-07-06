import { ref, App } from "vue";
import User from "../app/models/User";
import { useCurrentUser } from "../app/services/current-user";
import { useSiteSettings } from "../app/services/site-settings";
import { PiniaStore } from "../app/lib/Pinia";
import { green, red } from "console-log-colors";

interface PreloadedData {
    currentUser: any | null; // Cambiado temporalmente a 'any' para instanciar, ideal tiparlo según el payload crudo
    SiteSettings: any;
    isMobile: boolean;
    homepageData: any;
}

export const showPreloaderError = (error?: Error): void => {
    document.getElementById("c-splash")?.remove();
    if (document.getElementById("preload-failed")) return;

    const errorDiv = document.createElement("div");
    errorDiv.id = "preload-failed";
    errorDiv.className = "fixed inset-0 z-50 flex items-center justify-center p-4 font-sans";
    errorDiv.style.cssText = "background: var(--c-background-color, #090b10);";

    const errorHtml = `
        <div style="
            background: var(--c-surface-1, rgba(255,255,255,0.03));
            border: 1px solid var(--c-border-default, rgba(255,255,255,0.08));
            border-radius: 20px;
            padding: 3rem 2.5rem;
            max-width: 420px;
            width: 100%;
            text-align: center;
            box-shadow: 0 25px 60px rgba(0,0,0,0.4);
            backdrop-filter: blur(24px);
            -webkit-backdrop-filter: blur(24px);
        ">
            <!-- Icon -->
            <div style="
                width: 64px;
                height: 64px;
                margin: 0 auto 1.5rem;
                border-radius: 16px;
                background: rgba(255,255,255,0.04);
                border: 1px solid rgba(255,255,255,0.06);
                display: flex;
                align-items: center;
                justify-content: center;
            ">
                <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="var(--c-danger, #ff9494)" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="12" y1="8" x2="12" y2="12"/>
                    <line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
            </div>

            <!-- Title -->
            <h1 style="
                font-size: 1.35rem;
                font-weight: 700;
                letter-spacing: -0.02em;
                margin: 0 0 0.5rem;
                color: var(--c-text-primary, rgba(255,255,255,0.92));
            ">Algo salió mal</h1>

            <!-- Message -->
            <p style="
                font-size: 0.875rem;
                line-height: 1.6;
                margin: 0 0 1.75rem;
                color: var(--c-text-secondary, rgba(255,255,255,0.62));
            ">CinelarTV no pudo iniciarse correctamente. Por favor, intenta recargar la página.</p>

            <!-- Error details (hidden by default) -->
            <div id="error-details-container" style="display:none; margin-bottom: 1.5rem; text-align: left;">
                <pre id="error-details" style="
                    background: rgba(0,0,0,0.3);
                    color: var(--c-danger, #ff9494);
                    padding: 0.875rem 1rem;
                    border-radius: 10px;
                    overflow-x: auto;
                    font-size: 0.7rem;
                    font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
                    line-height: 1.6;
                    border: 1px solid rgba(255,255,255,0.04);
                    margin: 0;
                    max-height: 180px;
                "></pre>
            </div>

            <!-- Button -->
            <button id="reload-app-btn" style="
                display: inline-flex;
                align-items: center;
                justify-content: center;
                gap: 0.5rem;
                padding: 0.75rem 2rem;
                font-size: 0.875rem;
                font-weight: 600;
                color: #000;
                background: #fff;
                border: none;
                border-radius: 12px;
                cursor: pointer;
                transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
                outline: none;
                width: 100%;
            ">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="23 4 23 10 17 10"/>
                    <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"/>
                </svg>
                Recargar
            </button>

            <!-- Secondary link -->
            <a href="/" style="
                display: block;
                margin-top: 0.875rem;
                font-size: 0.8rem;
                color: var(--c-text-muted, rgba(255,255,255,0.45));
                text-decoration: none;
                transition: color 0.15s;
            ">Volver al inicio</a>
        </div>
    `;

    errorDiv.innerHTML = errorHtml;

    if (error) {
        const detailsContainer = errorDiv.querySelector("#error-details-container");
        const detailsText = errorDiv.querySelector("#error-details");
        if (detailsContainer && detailsText) {
            detailsContainer.style.display = "block";
            detailsText.textContent = error.stack || error.message;
        }
    }

    const reloadBtn = errorDiv.querySelector("#reload-app-btn");
    reloadBtn?.addEventListener("click", () => window.location.reload());
    reloadBtn?.addEventListener("mouseenter", () => {
        (reloadBtn as HTMLElement).style.transform = "scale(1.02)";
        (reloadBtn as HTMLElement).style.boxShadow = "0 4px 16px rgba(255,255,255,0.15)";
    });
    reloadBtn?.addEventListener("mouseleave", () => {
        (reloadBtn as HTMLElement).style.transform = "scale(1)";
        (reloadBtn as HTMLElement).style.boxShadow = "none";
    });

    const link = errorDiv.querySelector("a");
    link?.addEventListener("mouseenter", () => {
        (link as HTMLElement).style.color = "var(--c-text-secondary, rgba(255,255,255,0.62))";
    });
    link?.addEventListener("mouseleave", () => {
        (link as HTMLElement).style.color = "var(--c-text-muted, rgba(255,255,255,0.45))";
    });

    document.body.appendChild(errorDiv);
};

// ----------------------------------------------------------------------
// Inicialización Segura
// ----------------------------------------------------------------------
let preloaded: PreloadedData;
const preloadedDataElement = document.getElementById("data-preloaded");

try {
    if (!preloadedDataElement || !preloadedDataElement.dataset.preloaded) {
        throw new Error("Essential preloaded data not found in DOM");
    }

    // Parseo seguro: si el JSON está malformado, cae en el catch
    preloaded = JSON.parse(preloadedDataElement.dataset.preloaded) as PreloadedData;

} catch (e) {
    const bootError = new Error(`Unable to boot CinelarTV: ${(e as Error).message}`);
    console.error(red.bold("[CinelarTV Boot Error]"), bootError);
    showPreloaderError(bootError);
    throw bootError; // Detenemos la ejecución del script aquí
}

// Transformación de datos
preloaded.currentUser = preloaded.currentUser ? new User(preloaded.currentUser) : null;
const homepageData = ref(preloaded.homepageData || null);

const setPreloadedData = () => {
    const { setUser } = useCurrentUser(PiniaStore);
    const { setSiteSettings } = useSiteSettings(PiniaStore);

    setUser(preloaded.currentUser);
    setSiteSettings(preloaded.SiteSettings);
};

setPreloadedData();

// ----------------------------------------------------------------------
// Instalación del Plugin Vue
// ----------------------------------------------------------------------
const install = (app: App): void => {
    app.use(PiniaStore);
    Object.assign(app.config.globalProperties, preloaded);

    app.provide("currentUser", preloaded.currentUser);
    app.provide("SiteSettings", preloaded.SiteSettings);
    app.provide("isMobile", preloaded.isMobile);
    app.provide("homepageData", homepageData);

    console.log(`${green.bold("[CinelarTV]")} Preloaded data installed`);
};

export default {
    install,
};

export const { isMobile } = preloaded;

export const Language = {
    // @ts-ignore
    current: preloaded.currentUser?.locale || preloaded.SiteSettings?.default_locale,
    default: preloaded.SiteSettings?.default_locale,
};