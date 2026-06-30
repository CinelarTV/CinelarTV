import { defineComponent } from 'vue';
import CSpinner from '@/components/c-spinner';

export default defineComponent({
    name: 'SpinnersSection',
    setup() {
        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">Spinners</h1>
                <p class="styleguide-section__description">
                    Indicador de carga con <code>c-spinner</code>. Soporta tamaño normal y pequeño.
                </p>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Default</h2>
                    <div class="styleguide-row">
                        <CSpinner />
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Small</h2>
                    <div class="styleguide-row">
                        <CSpinner small={true} />
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Inline Usage</h2>
                    <div class="styleguide-row">
                        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                            <CSpinner small={true} />
                            <span>Loading data...</span>
                        </div>
                    </div>
                </div>
            </div>
        );
    }
});
