// PluginOutlet.tsx
import { defineComponent, computed, PropType } from 'vue';
import { usePluginOutlets } from '@/stores/pluginOutlets';
import { PluginOutletName } from '@/stores/pluginOutletNames';

export default defineComponent({
    name: 'PluginOutlet',
    props: {
        name: { type: String as PropType<PluginOutletName>, required: true }
    },
    setup(props) {
        const pluginOutlets = usePluginOutlets();
        // Autoregistra el espacio si no existe (ya no es necesario, pero por compatibilidad)
        if (!pluginOutlets.outlets[props.name]) {
            pluginOutlets.outlets[props.name] = [];
        }
        const components = computed(() => pluginOutlets.get(props.name));
        return () => {
            if (!components.value.length) return null;
            return (
                <div class={`plugin-outlet plugin-outlet-${props.name}`}>
                    {components.value.map((Comp: any, i: PropertyKey) => <Comp key={i} />)}
                </div>
            );
        };
    }
});

export function registerPluginOutlet(name: PluginOutletName, component: any) {
    usePluginOutlets().register(name, component);
}