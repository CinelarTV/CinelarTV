import { SafeMode } from "../pre-initializers/safe-mode";
import { useSiteSettings } from "../app/services/site-settings";
import { PiniaStore } from "../app/lib/Pinia";
const { siteSettings } = useSiteSettings(PiniaStore);


const loadPluginComponents = () => {
    // Ajusta la ruta según la estructura real de tus plugins
    const modules = import.meta.glob('/plugins/cinelar-watchparty/**/components/*.vue', { eager: true });
    const components = {};

    Object.entries(modules).forEach(([path, module]) => {
        const match = path.match(/\/([A-Za-z0-9_-]+)\.vue$/i);
        if (match && module.default) {
            const componentName = match[1];
            components[componentName] = module.default;
        }
    });

    return [components];
};

const pluginComponents = loadPluginComponents();

export default {
    install: (app) => {
        if (SafeMode.enabled && SafeMode.noPlugins) return;
        if (!siteSettings.enable_plugins) return;
        pluginComponents.forEach(plugin => {
            Object.entries(plugin).forEach(([name, component]) => {
                console.log(`Registering plugin component ${name}`);
                app.component(name, component);
            });
        });
    }
};
