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
    // 1. Limpiar splash screen si existe
    document.getElementById("c-splash")?.remove();

    // Evitar duplicados si la función se llama múltiples veces
    if (document.getElementById("preload-failed")) return;

    // 2. Crear contenedor principal
    const errorDiv = document.createElement("div");
    errorDiv.id = "preload-failed";
    // Clases de Tailwind para un diseño moderno (Dark mode por defecto, centrado, modal)
    errorDiv.className = "fixed inset-0 z-50 flex items-center justify-center bg-gray-900/95 backdrop-blur-sm p-4 font-sans";

    // 3. Estructura interna (Icono, Título, Mensaje, Botón)
    const errorHtml = `
        <div class="bg-gray-800 rounded-2xl shadow-2xl p-8 max-w-lg w-full text-center border border-gray-700">
            <div class="mb-6 flex justify-center text-red-500">
                <svg class="w-16 h-16" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>
                </svg>
            </div>
            <h1 class="text-2xl font-bold text-white mb-2">¡Oops! Algo salió mal</h1>
            <p class="text-gray-400 mb-6">CinelarTV no pudo iniciarse correctamente. Por favor, recarga la página.</p>
            
            <div id="error-details-container" class="hidden mb-6 text-left">
                <pre id="error-details" class="bg-gray-950 text-red-400 p-4 rounded-lg overflow-x-auto text-xs font-mono border border-red-900/30"></pre>
            </div>

            <button id="reload-app-btn" class="bg-red-600 hover:bg-red-700 text-white font-semibold py-3 px-8 rounded-xl transition-all duration-200 focus:outline-none focus:ring-4 focus:ring-red-500/50 shadow-lg shadow-red-600/20">
                Recargar Aplicación
            </button>
        </div>
    `;

    errorDiv.innerHTML = errorHtml;

    // 4. Inyectar el error de forma segura (previniendo XSS en caso de que el error venga de una fuente externa)
    if (error) {
        const detailsContainer = errorDiv.querySelector("#error-details-container");
        const detailsText = errorDiv.querySelector("#error-details");
        if (detailsContainer && detailsText) {
            detailsContainer.classList.remove("hidden");
            detailsText.textContent = error.stack || error.message;
        }
    }

    // 5. Agregar evento al botón
    const reloadBtn = errorDiv.querySelector("#reload-app-btn");
    reloadBtn?.addEventListener("click", () => window.location.reload());

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