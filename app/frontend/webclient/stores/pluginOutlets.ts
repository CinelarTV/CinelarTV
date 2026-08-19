import { defineStore } from 'pinia';

export const usePluginOutlets = defineStore('pluginOutlets', {
    state: () => ({
        outlets: {} as Record<string, any[]>
    }),
    actions: {
        register(name: string, registration: any) {
            if (!this.outlets[name]) {
                this.outlets[name] = [];
            }
            const index = this.outlets[name].findIndex((item: any) => item.id === registration.id);
            if (index >= 0) this.outlets[name].splice(index, 1, registration);
            else this.outlets[name].push(registration);
            this.outlets[name].sort((a: any, b: any) => (b.priority || 0) - (a.priority || 0));
            return () => this.remove(name, registration.id);
        },
        remove(name: string, id: string) {
            this.outlets[name] = (this.outlets[name] || []).filter((item: any) => item.id !== id);
        },
        get(name: string) {
            return this.outlets[name] || [];
        }
    }
});
