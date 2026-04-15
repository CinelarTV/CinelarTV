import { defineComponent, PropType } from 'vue';

type InputControlOption = {
    value: string;
    label: string;
};

export default defineComponent({
    name: 'BillingInputControl',
    props: {
        modelValue: {
            type: [String, Number] as PropType<string | number>,
            default: '',
        },
        as: {
            type: String as PropType<'input' | 'select'>,
            default: 'input',
        },
        type: {
            type: String,
            default: 'text',
        },
        placeholder: {
            type: String,
            default: '',
        },
        disabled: {
            type: Boolean,
            default: false,
        },
        required: {
            type: Boolean,
            default: false,
        },
        options: {
            type: Array as PropType<InputControlOption[]>,
            default: () => [],
        },
        selectPlaceholder: {
            type: String,
            default: '',
        },
    },
    emits: ['update:modelValue'],
    setup(props, { emit, attrs }) {
        const updateValue = (value: string) => {
            emit('update:modelValue', value);
        };

        return () => {
            if (props.as === 'select') {
                return (
                    <select
                        class="billing-page__input"
                        value={String(props.modelValue ?? '')}
                        disabled={props.disabled}
                        required={props.required}
                        onChange={(event) => updateValue((event.target as HTMLSelectElement).value)}
                        {...attrs}
                    >
                        {props.selectPlaceholder && (
                            <option value="" disabled>
                                {props.selectPlaceholder}
                            </option>
                        )}
                        {props.options.map((option) => (
                            <option key={option.value} value={option.value}>
                                {option.label}
                            </option>
                        ))}
                    </select>
                );
            }

            return (
                <input
                    class="billing-page__input"
                    type={props.type}
                    value={String(props.modelValue ?? '')}
                    placeholder={props.placeholder}
                    disabled={props.disabled}
                    required={props.required}
                    onInput={(event) => updateValue((event.target as HTMLInputElement).value)}
                    {...attrs}
                />
            );
        };
    },
});
