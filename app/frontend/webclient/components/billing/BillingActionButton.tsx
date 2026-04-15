import { defineComponent, PropType } from 'vue';
import CIcon from '@/components/c-icon.vue';

export default defineComponent({
    name: 'BillingActionButton',
    props: {
        icon: {
            type: String,
            default: '',
        },
        loadingIcon: {
            type: String,
            default: 'loader',
        },
        loading: {
            type: Boolean,
            default: false,
        },
        type: {
            type: String as PropType<'button' | 'submit'>,
            default: 'button',
        },
        variant: {
            type: String as PropType<'default' | 'primary' | 'secondary' | 'danger'>,
            default: 'default',
        },
        large: {
            type: Boolean,
            default: false,
        },
        disabled: {
            type: Boolean,
            default: false,
        },
    },
    emits: ['click'],
    setup(props, { slots, emit, attrs }) {
        const classes = () => [
            'billing-page__btn',
            props.variant === 'primary' && 'billing-page__btn--primary',
            props.variant === 'secondary' && 'billing-page__btn--secondary',
            props.variant === 'danger' && 'billing-page__btn--danger',
            props.large && 'billing-page__btn--large',
        ];

        return () => (
            <button
                type={props.type}
                class={classes()}
                disabled={props.disabled || props.loading}
                onClick={(event) => emit('click', event)}
                {...attrs}
            >
                {(props.loading || props.icon) && (
                    <CIcon
                        icon={props.loading ? props.loadingIcon : props.icon}
                        size={18}
                        class={props.loading ? 'animate-spin' : ''}
                    />
                )}
                {slots.default?.()}
            </button>
        );
    },
});
