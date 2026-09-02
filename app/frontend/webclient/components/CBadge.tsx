import { defineComponent, PropType } from 'vue';

export default defineComponent({
    name: 'CBadge',
    props: {
        variant: {
            type: String as PropType<'default' | 'primary' | 'success' | 'warning' | 'danger' | 'info' | 'muted'>,
            default: 'default'
        },
        size: {
            type: String as PropType<'sm' | 'md' | 'lg'>,
            default: 'md'
        },
        pill: {
            type: Boolean,
            default: false
        },
        dot: {
            type: Boolean,
            default: false
        },
        bordered: {
            type: Boolean,
            default: false
        }
    },
    setup(props, { slots }) {
        return () => (
            <span
                class={[
                    'c-badge',
                    `c-badge--${props.variant}`,
                    `c-badge--${props.size}`,
                    props.pill && 'c-badge--pill',
                    props.bordered && 'c-badge--bordered'
                ]}
            >
                {props.dot && <span class="c-badge__dot" />}
                {slots.default?.()}
            </span>
        );
    }
});
