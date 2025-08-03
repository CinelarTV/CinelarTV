/* 
    IMPORTANT: This file is part of the frontend bootstrap process.
    It is responsible for initializing the frontend application
    and preloading necessary resources.
    Ensure that any changes here are thoroughly tested.
*/

import { createRoot } from 'react-dom/client';
import { showPreloaderError, usePreloadedStore } from "../webclient/pre-initializers/essentials-preload.ts";
import { App } from "../webclient/App.tsx";


console.log('CinelarTV frontend bootstrap initialized');

try {
    // Elimina <noscript> si existe
    document.querySelector('noscript')?.remove();

    // Verifica que el preload se haya realizado correctamente
    const preloaded = usePreloadedStore.getState();
    if (!preloaded || !preloaded.SiteSettings) {
        showPreloaderError(new Error('Essential preloaded data not found'));
        throw new Error('Essential preloaded data not found');
    }

    // Inicializa la app React
    const rootElement = document.getElementById('cinelartv');
    if (!rootElement) throw new Error('No #cinelartv element found');
    const root = createRoot(rootElement);

    root.render(<App />);

    // Aquí puedes renderizar tu componente principal, por ejemplo:
    // root.render(<App />);

    // Espacio para cargar PluginAPI y JS personalizado si lo necesitas
    // Ejemplo:
    // import('./PluginAPI').then(...)
    // if (preloaded.SiteSettings.custom_js) { ... }

} catch (error) {
    console.error(error);
    showPreloaderError(error instanceof Error ? error : new Error(String(error)));
}

