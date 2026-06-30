import { defineComponent, ref } from 'vue';
import CInput from '@/components/forms/c-input.vue';
import CTextarea from '@/components/forms/c-textarea.vue';
import CSelect from '@/components/forms/c-select.vue';
import CFormRow from '@/components/forms/CFormRow.tsx';

const sampleOptions = [
    { label: 'Option 1', value: 'opt1' },
    { label: 'Option 2', value: 'opt2' },
    { label: 'Option 3', value: 'opt3' },
    { label: 'Option 4 (Long)', value: 'opt4' }
];

export default defineComponent({
    name: 'InputsSection',
    setup() {
        const textValue = ref('');
        const textareaValue = ref('');
        const selectValue = ref('');
        const errorValue = ref('This field is required');

        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">Inputs</h1>
                <p class="styleguide-section__description">
                    Componentes de formulario: <code>c-input</code>, <code>c-textarea</code>, <code>c-select</code>, <code>c-form-row</code>.
                </p>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Text Input</h2>
                    <div class="styleguide-row" style={{ maxWidth: '400px' }}>
                        <CInput
                            modelValue={textValue.value}
                            onUpdate:modelValue={(v: string) => { textValue.value = v; }}
                            placeholder="Enter text..."
                        />
                    </div>
                    <p class="styleguide-hint">Value: "{textValue.value}"</p>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Textarea</h2>
                    <div class="styleguide-row" style={{ maxWidth: '400px' }}>
                        <CTextarea
                            modelValue={textareaValue.value}
                            onUpdate:modelValue={(v: string) => { textareaValue.value = v; }}
                            placeholder="Enter description..."
                            rows={4}
                        />
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Select</h2>
                    <div class="styleguide-row" style={{ maxWidth: '300px' }}>
                        <CSelect
                            options={sampleOptions}
                            modelValue={selectValue.value}
                            onUpdate:modelValue={(v: string) => { selectValue.value = v; }}
                            placeholder="Choose an option"
                        />
                    </div>
                    <p class="styleguide-hint">Value: "{selectValue.value}"</p>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Input States</h2>
                    <div class="styleguide-row" style={{ maxWidth: '400px' }}>
                        <CInput placeholder="Normal state" />
                        <CInput placeholder="Disabled" disabled />
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">CFormRow</h2>
                    <p class="styleguide-hint">
                        Wrapper que agrupa label + input + error/hint con estilo consistente.
                    </p>
                    <div style={{ maxWidth: '400px' }}>
                        <CFormRow label="Username" for="username" required>
                            <CInput placeholder="Enter username" id="username" />
                        </CFormRow>

                        <CFormRow label="Email" for="email" hint="We'll never share your email">
                            <CInput placeholder="email@example.com" id="email" type="email" />
                        </CFormRow>

                        <CFormRow label="Password" for="password" error={errorValue.value}>
                            <CInput placeholder="Enter password" id="password" type="password" />
                        </CFormRow>

                        <CFormRow label="Bio" for="bio">
                            <CTextarea placeholder="Tell us about yourself..." id="bio" rows={3} />
                        </CFormRow>
                    </div>
                </div>
            </div>
        );
    }
});
