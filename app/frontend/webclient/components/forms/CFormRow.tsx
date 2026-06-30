import { defineComponent, PropType } from 'vue';

export default defineComponent({
    name: 'CFormRow',
    props: {
        label: String,
        for: String,
        error: String,
        hint: String,
        required: Boolean,
    },
    setup(props, { slots }) {
        return () => (
            <div class="c-form-row">
                {props.label && (
                    <label
                        for={props.for}
                        class="c-form-row__label"
                    >
                        {props.label}
                        {props.required && <span class="c-form-row__required">*</span>}
                    </label>
                )}
                <div class="c-form-row__control">
                    {slots.default?.()}
                </div>
                {props.error && (
                    <p class="c-form-row__error">{props.error}</p>
                )}
                {props.hint && !props.error && (
                    <p class="c-form-row__hint">{props.hint}</p>
                )}
            </div>
        );
    }
});
