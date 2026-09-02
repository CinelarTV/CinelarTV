import { defineComponent, PropType, ref, onMounted, onBeforeUnmount } from 'vue';
import CIcon from './c-icon.vue';

export interface DropdownItem {
    key: string;
    label?: string;
    icon?: string;
    danger?: boolean;
    disabled?: boolean;
    separator?: boolean;
    header?: boolean;
}

export default defineComponent({
    name: 'CDropdown',
    props: {
        items: {
            type: Array as PropType<DropdownItem[]>,
            required: true
        },
        placement: {
            type: String as PropType<'left' | 'right'>,
            default: 'left'
        },
        width: {
            type: String,
            default: 'auto'
        }
    },
    emits: ['select'],
    setup(props, { slots, emit }) {
        const isOpen = ref(false);
        const dropdownRef = ref<HTMLElement | null>(null);

        const toggle = () => { isOpen.value = !isOpen.value; };
        const close = () => { isOpen.value = false; };

        const onSelect = (item: DropdownItem) => {
            if (item.disabled || item.separator || item.header) return;
            emit('select', item);
            close();
        };

        const onClickOutside = (e: MouseEvent) => {
            if (dropdownRef.value && !dropdownRef.value.contains(e.target as Node)) {
                close();
            }
        };

        onMounted(() => document.addEventListener('click', onClickOutside));
        onBeforeUnmount(() => document.removeEventListener('click', onClickOutside));

        return () => (
            <div class="c-dropdown" ref={dropdownRef}>
                <div class="c-dropdown__trigger" onClick={toggle}>
                    {slots.trigger?.({ isOpen: isOpen.value })}
                </div>
                {isOpen.value && (
                    <div
                        class={[
                            'c-dropdown__menu',
                            `c-dropdown__menu--${props.placement}`
                        ]}
                        style={{ width: props.width }}
                    >
                        {props.items.map((item) => {
                            if (item.separator) {
                                return <div key={item.key} class="c-dropdown__separator" />;
                            }
                            if (item.header) {
                                return (
                                    <div key={item.key} class="c-dropdown__header">
                                        {item.label}
                                    </div>
                                );
                            }
                            return (
                                <button
                                    key={item.key}
                                    class={[
                                        'c-dropdown__item',
                                        item.danger && 'c-dropdown__item--danger',
                                        item.disabled && 'c-dropdown__item--disabled'
                                    ]}
                                    disabled={item.disabled}
                                    onClick={() => onSelect(item)}
                                >
                                    {item.icon && <CIcon icon={item.icon} size={16} />}
                                    <span>{item.label}</span>
                                </button>
                            );
                        })}
                    </div>
                )}
            </div>
        );
    }
});
