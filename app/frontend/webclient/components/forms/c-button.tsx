import { defineComponent, PropType } from 'vue';
import CIcon from '../c-icon.vue';

export default defineComponent({
    name: 'CButton',
    inheritAttrs: true,
    props: {
        variant: {
            type: String as PropType<string | null>,
            default: null
        },
        nativeType: {
            type: String as PropType<'button' | 'submit' | 'reset'>,
            default: 'button'
        },
        loading: {
            type: Boolean,
            default: false
        },
        icon: {
            type: String,
            default: ''
        },
    },
    emits: ['click'],
    setup(props, { slots, emit, attrs }) {
        const isAttrDisabled = () => {
            const disabledAttr = attrs.disabled;
            return disabledAttr === '' || disabledAttr === true || disabledAttr === 'true';
        };

        const handleClick = (e: MouseEvent) => {
            if (props.loading || isAttrDisabled()) return;
            emit('click', e);
        };

        return () => {
            const hasIcon = Boolean(props.icon);
            const { type: attrType, ...restAttrs } = attrs;
            const buttonType = (attrType as string) || props.nativeType;

            return (
                <button
                    {...restAttrs}
                    class={[
                        'c-button',
                        props.variant && `c-button--${props.variant}`,
                        props.loading && 'c-button--loading',
                    ]}
                    type={buttonType as 'button' | 'submit' | 'reset'}
                    disabled={props.loading || isAttrDisabled()}
                    aria-busy={props.loading ? 'true' : 'false'}
                    onClick={handleClick}
                >
                    <span
                        class="c-button__content"
                        aria-hidden={props.loading ? 'true' : undefined}
                    >
                        {hasIcon && (
                            <CIcon icon={props.icon} size={18} class={['icon', 'c-button__icon']} />
                        )}
                        <span class="c-button__label">{slots.default?.()}</span>
                    </span>

                    {props.loading && (
                        <span class="c-button__spinner" aria-hidden="true">
                            <CIcon
                                icon="loader"
                                size={18}
                                class={['icon', 'c-button__icon', 'animate-spin']}
                            />
                        </span>
                    )}
                </button>
            );
        };
    }
});