// PluginOutlet.tsx
import { defineComponent, computed, h, type PropType } from 'vue';
import { usePluginOutlets } from '@/stores/pluginOutlets';

export type PluginOutletRegistration = {
    id: string;
    pluginId?: string;
    component: any;
    priority?: number;
    when?: (context: Record<string, unknown>) => boolean;
};

const LEGACY_OUTLET_NAMES: Record<string, string> = {
    'player:top-controls:right': 'player.topControls.right',
    'player:after-media-player': 'player.afterMedia',
};

function canonicalOutletName(name: string) {
    return LEGACY_OUTLET_NAMES[name] || name;
}

export default defineComponent({
    name: 'PluginOutlet',
    props: {
        name: { type: String, required: true },
        context: { type: Object as PropType<Record<string, unknown>>, default: () => ({}) }
    },
    setup(props) {
        const pluginOutlets = usePluginOutlets();
        const outletName = canonicalOutletName(props.name);
        if (!pluginOutlets.outlets[outletName]) {
            pluginOutlets.outlets[outletName] = [];
        }
        const components = computed(() => pluginOutlets.get(outletName));
        return () => {
            if (!components.value.length) return null;
            return (
                <div class={`plugin-outlet plugin-outlet-${outletName.replace(/\./g, '-')}`}>
                    {components.value.filter((entry: PluginOutletRegistration) => !entry.when || entry.when(props.context))
                        .map((entry: PluginOutletRegistration) => h(entry.component, { key: entry.id, ...props.context }))}
                </div>
            );
        };
    }
});

export function registerPluginOutlet(name: string, registration: PluginOutletRegistration | any) {
    const normalized = registration?.component
        ? registration
        : { id: `legacy:${name}:${registration?.name || Math.random().toString(36).slice(2)}`, component: registration };
    return usePluginOutlets().register(canonicalOutletName(name), normalized);
}
