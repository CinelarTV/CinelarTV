import { defineStore } from 'pinia';

export const usePluginOutlets = defineStore('pluginOutlets', {
    state: () => ({
        outlets: {} as Record<string, any[]>
    }),
    actions: {
        register(name: string, component: any) {
            if (!this.outlets[name]) {
                this.outlets[name] = [];
            }
            this.outlets[name].push(component);
        },
        get(name: string) {
            return this.outlets[name] || [];
        }
    }
});
