import { defineComponent, PropType, ref } from 'vue';
import CIcon from './c-icon.vue';

export default defineComponent({
    name: 'CAlert',
    props: {
        type: {
            type: String as PropType<'info' | 'success' | 'warning' | 'danger'>,
            default: 'info'
        },
        title: {
            type: String,
            default: ''
        },
        icon: {
            type: String,
            default: ''
        },
        dismissible: {
            type: Boolean,
            default: false
        },
        borderless: {
            type: Boolean,
            default: false
        }
    },
    emits: ['dismiss'],
    setup(props, { slots, emit }) {
        const dismissed = ref(false);

        const defaultIcons: Record<string, string> = {
            info: 'info',
            success: 'check-circle',
            warning: 'alert-triangle',
            danger: 'alert-circle'
        };

        const iconName = () => props.icon || defaultIcons[props.type];

        const onDismiss = () => {
            dismissed.value = true;
            emit('dismiss');
        };

        return () => {
            if (dismissed.value) return null;

            return (
                <div
                    class={[
                        'c-alert',
                        `c-alert--${props.type}`,
                        props.borderless && 'c-alert--borderless'
                    ]}
                    role="alert"
                >
                    <CIcon icon={iconName()} size={18} class="c-alert__icon" />
                    <div class="c-alert__content">
                        {props.title && <strong class="c-alert__title">{props.title}</strong>}
                        <span class="c-alert__message">{slots.default?.()}</span>
                    </div>
                    {props.dismissible && (
                        <button class="c-alert__close" onClick={onDismiss} aria-label="Dismiss">
                            <CIcon icon="x" size={16} />
                        </button>
                    )}
                </div>
            );
        };
    }
});
