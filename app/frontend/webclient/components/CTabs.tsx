import { defineComponent, ref, watch, onMounted, nextTick, PropType } from 'vue';
import CIcon from './c-icon.vue';

export interface TabItem {
    key: string;
    label: string;
    icon?: string;
    disabled?: boolean;
}

export default defineComponent({
    name: 'CTabs',
    props: {
        modelValue: {
            type: String,
            required: true
        },
        items: {
            type: Array as PropType<TabItem[]>,
            required: true
        },
        variant: {
            type: String as PropType<'default' | 'pills' | 'underline'>,
            default: 'default'
        },
        size: {
            type: String as PropType<'sm' | 'md'>,
            default: 'md'
        }
    },
    emits: ['update:modelValue'],
    setup(props, { slots, emit }) {
        const listRef = ref<HTMLDivElement>();
        const indicatorStyle = ref<{ left: string; width: string }>({ left: '0px', width: '0px' });

        const updateIndicator = () => {
            const list = listRef.value;
            if (!list) return;
            const activeEl = list.querySelector('.c-tabs__tab--active') as HTMLElement | null;
            if (!activeEl) return;

            const listRect = list.getBoundingClientRect();
            const tabRect = activeEl.getBoundingClientRect();

            indicatorStyle.value = {
                left: `${tabRect.left - listRect.left + list.scrollLeft}px`,
                width: `${tabRect.width}px`,
            };
        };

        onMounted(() => nextTick(updateIndicator));
        watch(() => props.modelValue, () => nextTick(updateIndicator));

        const selectTab = (key: string, disabled?: boolean) => {
            if (disabled) return;
            emit('update:modelValue', key);
        };

        return () => (
            <div class={['c-tabs', `c-tabs--${props.variant}`, `c-tabs--${props.size}`]}>
                <div class="c-tabs__list" role="tablist" ref={listRef}>
                    {props.items.map((tab) => (
                        <button
                            key={tab.key}
                            class={[
                                'c-tabs__tab',
                                props.modelValue === tab.key && 'c-tabs__tab--active',
                                tab.disabled && 'c-tabs__tab--disabled'
                            ]}
                            role="tab"
                            aria-selected={props.modelValue === tab.key}
                            disabled={tab.disabled}
                            onClick={() => selectTab(tab.key, tab.disabled)}
                        >
                            {tab.icon && <CIcon icon={tab.icon} size={16} />}
                            <span>{tab.label}</span>
                        </button>
                    ))}
                    <span
                        class="c-tabs__indicator"
                        style={indicatorStyle.value}
                    />
                </div>
                <div class="c-tabs__panel" role="tabpanel">
                    {slots.default?.()}
                </div>
            </div>
        );
    }
});
