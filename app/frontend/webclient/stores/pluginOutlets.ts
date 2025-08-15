import { defineStore } from 'pinia';
import { PLUGIN_OUTLET_NAMES, PluginOutletName } from './pluginOutletNames';

export const usePluginOutlets = defineStore('pluginOutlets', {
    state: () => ({
        outlets: Object.fromEntries(PLUGIN_OUTLET_NAMES.map(name => [name, []])) as Record<PluginOutletName, any[]>
    }),
    actions: {
        register(name: PluginOutletName, component: any) {
            this.outlets[name].push(component);
        },
        get(name: PluginOutletName) {
            return this.outlets[name] || [];
        },
        getAllOutletsNames() {
            return PLUGIN_OUTLET_NAMES;
        }
    }
});
