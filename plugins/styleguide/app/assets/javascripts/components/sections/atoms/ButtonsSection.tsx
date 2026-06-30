import { defineComponent, ref } from 'vue';
import CButton from '@/components/forms/c-button';

export default defineComponent({
    name: 'ButtonsSection',
    setup() {
        const loading = ref(false);

        const toggleLoading = () => {
            loading.value = true;
            setTimeout(() => { loading.value = false; }, 2000);
        };

        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">Buttons</h1>
                <p class="styleguide-section__description">
                    Componente <code>c-button</code> con soporte para variantes, iconos y estado de carga.
                </p>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Default</h2>
                    <div class="styleguide-row">
                        <CButton>Default Button</CButton>
                        <CButton icon="search">With Icon</CButton>
                        <CButton loading={loading.value} onClick={toggleLoading}>
                            {loading.value ? 'Loading...' : 'Click to Load'}
                        </CButton>
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Variants</h2>
                    <div class="styleguide-row">
                        <CButton variant="primary">Primary</CButton>
                        <CButton variant="danger">Danger</CButton>
                        <CButton variant="ghost">Ghost</CButton>
                        <CButton variant="link">Link</CButton>
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Icon Only</h2>
                    <div class="styleguide-row">
                        <CButton icon="search" aria-label="Search" />
                        <CButton icon="settings" aria-label="Settings" />
                        <CButton icon="trash" aria-label="Delete" />
                        <CButton icon="plus" aria-label="Add" />
                        <CButton icon="edit" aria-label="Edit" />
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Disabled</h2>
                    <div class="styleguide-row">
                        <CButton disabled>Disabled</CButton>
                        <CButton disabled icon="lock">Locked</CButton>
                    </div>
                </div>
            </div>
        );
    }
});
