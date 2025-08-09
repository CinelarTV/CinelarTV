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
        const handleClick = (e: MouseEvent) => {
            if (!props.loading) emit('click', e);
        };
        return () => (
            <button
                class={[
                    'c-button',
                    props.type === 'danger' && 'c-button--danger',
                    props.loading && 'c-button--loading',
                ]}
                disabled={props.loading}
                {...attrs}
                onClick={handleClick}
            >
                {props.loading && (
                    <span>
                        <CIcon icon="loader" size={18} class="icon loading-request animate-spin" />
                    </span>
                )}
                {!props.loading && props.icon && (
                    <CIcon icon={props.icon} size={18} class="icon" />
                )}
                {slots.default?.()}
            </button>
        );
    }
});
