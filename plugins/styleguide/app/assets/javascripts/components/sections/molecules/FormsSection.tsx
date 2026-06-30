import { defineComponent, ref } from 'vue';
import CButton from '@/components/forms/c-button';
import CInput from '@/components/forms/c-input.vue';
import CTextarea from '@/components/forms/c-textarea.vue';
import CSelect from '@/components/forms/c-select.vue';
import CFormRow from '@/components/forms/CFormRow.tsx';

const selectOptions = [
    { label: 'Movie', value: 'movie' },
    { label: 'Series', value: 'series' },
    { label: 'Documentary', value: 'documentary' }
];

export default defineComponent({
    name: 'FormsSection',
    setup() {
        const name = ref('');
        const description = ref('');
        const type = ref('');
        const submitted = ref(false);

        const handleSubmit = () => {
            submitted.value = true;
            setTimeout(() => { submitted.value = false; }, 2000);
        };

        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">Forms</h1>
                <p class="styleguide-section__description">
                    Ejemplo de formulario completo usando los componentes de entrada y <code>CFormRow</code>.
                </p>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Content Form</h2>
                    <div class="styleguide-form" style={{ maxWidth: '480px' }}>
                        <CFormRow label="Title" for="sg-title" required>
                            <CInput
                                modelValue={name.value}
                                onUpdate:modelValue={(v: string) => { name.value = v; }}
                                placeholder="Enter content title"
                                id="sg-title"
                            />
                        </CFormRow>

                        <CFormRow label="Type" for="sg-type">
                            <CSelect
                                options={selectOptions}
                                modelValue={type.value}
                                onUpdate:modelValue={(v: string) => { type.value = v; }}
                                placeholder="Select type"
                                id="sg-type"
                            />
                        </CFormRow>

                        <CFormRow label="Description" for="sg-desc">
                            <CTextarea
                                modelValue={description.value}
                                onUpdate:modelValue={(v: string) => { description.value = v; }}
                                placeholder="Enter description..."
                                rows={4}
                                id="sg-desc"
                            />
                        </CFormRow>

                        <div class="styleguide-form__actions">
                            <CButton variant="ghost">Cancel</CButton>
                            <CButton
                                variant="primary"
                                onClick={handleSubmit}
                                loading={submitted.value}
                            >
                                {submitted.value ? 'Saving...' : 'Save'}
                            </CButton>
                        </div>
                    </div>
                </div>
            </div>
        );
    }
});
