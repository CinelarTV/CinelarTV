import { SafeMode } from "../pre-initializers/safe-mode";
import { useSiteSettings } from "../app/services/site-settings";
import { PiniaStore } from "../app/lib/Pinia";
const { siteSettings } = useSiteSettings(PiniaStore);


const loadPluginComponents = () => {
    const componentsContext = require.context('pluginsDir', true, /components\/.+\.vue$/i);
    const components = {};

    componentsContext.keys().forEach((componentPath) => {
        const componentName = componentPath.match(/\/([A-Za-z0-9_-]+)\.vue$/i)[1]; // Extraer el nombre del componente de la ruta
        const componentModule = componentsContext(componentPath);

        if (componentModule.default) {
            components[componentName] = componentModule.default;
        }
    });

    return [components]
};

const pluginComponents = loadPluginComponents();

export default {
    install: (app) => {
        if(SafeMode.enabled && SafeMode.noPlugins) return;
        if(!siteSettings.enable_plugins) return;
        pluginComponents.forEach(plugin => {
            Object.entries(plugin).forEach(([name, component]) => {
                console.log(`Registering plugin component ${name}`)
                app.component(name, component)
            })
        })
    }
}
