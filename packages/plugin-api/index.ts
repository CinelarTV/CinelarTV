// Re-exportamos la clase base PluginAPI
import PluginAPI from "../../app/frontend/webclient/lib/PluginAPI";
export { PluginAPI };

import { registerPluginOutlet } from "../../app/frontend/webclient/components/PluginOutlet";
export { registerPluginOutlet };

export {
    createPluginHost,
    definePlugin,
    PluginHost,
    PLUGIN_API_VERSION,
} from "../../app/frontend/webclient/plugins/PluginHost";
export type { PluginApi, PluginDefinition, PluginRegistryEntry } from "../../app/frontend/webclient/plugins/PluginHost";

// Exportamos también la factoría propuesta
export const createPluginAPI = (app: any) => {
    return new PluginAPI("1.0.0", app);
};
