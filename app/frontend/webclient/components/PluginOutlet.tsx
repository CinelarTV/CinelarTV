// PluginOutlet.tsx
import { defineComponent, computed } from 'vue';
import { usePluginOutlets } from '@/stores/pluginOutlets';

export default defineComponent({
    name: 'PluginOutlet',
    props: {
        name: { type: String, required: true }
    },
    setup(props) {
        const pluginOutlets = usePluginOutlets();
        if (!pluginOutlets.outlets[props.name]) {
            pluginOutlets.outlets[props.name] = [];
        }
        const components = computed(() => pluginOutlets.get(props.name));
        return () => {
            if (!components.value.length) return null;
            return (
                <div class={`plugin-outlet plugin-outlet-${props.name}`}>
                    {components.value.map((Comp: any, i: number) => <Comp key={i} />)}
                </div>
            );
        };
    }
});

export function registerPluginOutlet(name: string, component: any) {
    usePluginOutlets().register(name, component);
}
