import { defineComponent, PropType, ref } from 'vue';

export default defineComponent({
    name: 'CTooltip',
    props: {
        text: {
            type: String,
            default: ''
        },
        placement: {
            type: String as PropType<'top' | 'bottom' | 'left' | 'right'>,
            default: 'top'
        },
        delay: {
            type: Number,
            default: 200
        }
    },
    setup(props, { slots }) {
        const visible = ref(false);
        let timeout: ReturnType<typeof setTimeout> | null = null;

        const show = () => {
            if (timeout) clearTimeout(timeout);
            timeout = setTimeout(() => { visible.value = true; }, props.delay);
        };

        const hide = () => {
            if (timeout) clearTimeout(timeout);
            visible.value = false;
        };

        return () => (
            <div
                class="c-tooltip-wrapper"
                onMouseenter={show}
                onMouseleave={hide}
                onFocus={show}
                onBlur={hide}
            >
                {slots.default?.()}
                {props.text && (
                    <div
                        class={[
                            'c-tooltip',
                            `c-tooltip--${props.placement}`,
                            visible.value && 'c-tooltip--visible'
                        ]}
                        role="tooltip"
                    >
                        {props.text}
                    </div>
                )}
            </div>
        );
    }
});
