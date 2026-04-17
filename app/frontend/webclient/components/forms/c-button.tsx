import { defineComponent, PropType } from 'vue';
import CIcon from '../c-icon.vue';

export default defineComponent({
    name: 'CButton',
    props: {
        onClick: Function as PropType<(e: MouseEvent) => void>,
        type: String as PropType<'danger' | null>,
        loading: Boolean,
        icon: {
            type: String,
            default: ''
        }
    },
    emits: ['click'],
    setup(props, { slots, emit, attrs }) {
        const isAttrDisabled = () => {
            const disabledAttr = attrs.disabled;
            return disabledAttr === '' || disabledAttr === true || disabledAttr === 'true';
        };

        const handleClick = (e: MouseEvent) => {
            if (!props.loading) emit('click', e);
        };

        return () => (
            (() => {
                const hasIcon = Boolean(props.icon);
                const showOverlaySpinner = props.loading && !hasIcon;

                return (
                    <button
                        class={[
                            'c-button',
                            props.type === 'danger' && 'c-button--danger',
                            props.loading && 'c-button--loading',
                            hasIcon && 'c-button--with-icon',
                            showOverlaySpinner && 'c-button--loading-no-icon',
                        ]}
                        {...attrs}
                        disabled={props.loading || isAttrDisabled()}
                        aria-busy={props.loading ? 'true' : 'false'}
                        onClick={handleClick}
                    >
                        <span class="c-button__content">
                            {hasIcon && (
                                <CIcon
                                    icon={props.loading ? 'loader' : props.icon}
                                    size={18}
                                    class={[
                                        'icon',
                                        'c-button__icon',
                                        props.loading && 'c-button__icon--loading',
                                        props.loading && 'animate-spin',
                                    ]}
                                />
                            )}
                            <span class="c-button__label">{slots.default?.()}</span>
                        </span>

                        {showOverlaySpinner && (
                            <span class="c-button__spinner-overlay" aria-hidden="true">
                                <CIcon
                                    icon="loader"
                                    size={16}
                                    class={['icon', 'c-button__icon', 'c-button__icon--loading', 'animate-spin']}
                                />
                            </span>
                        )}
                    </button>
                );
            })()
        );
    }
});
