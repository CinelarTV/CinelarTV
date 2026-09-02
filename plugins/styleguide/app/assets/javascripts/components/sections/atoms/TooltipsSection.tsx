import { defineComponent } from 'vue';
import CTooltip from '@/components/CTooltip';

export default defineComponent({
    name: 'TooltipsSection',
    setup() {
        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">Tooltips</h1>
                <p class="styleguide-section__description">
                    Componente <code>c-tooltip</code> con 4 posiciones y soporte para contenido rich.
                </p>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Positions</h2>
                    <div class="styleguide-row" style={{ gap: '32px', justifyContent: 'center', padding: '40px 0' }}>
                        <CTooltip text="Tooltip on top" placement="top">
                            <button class="styleguide-tooltip-trigger">Top</button>
                        </CTooltip>
                        <CTooltip text="Tooltip on bottom" placement="bottom">
                            <button class="styleguide-tooltip-trigger">Bottom</button>
                        </CTooltip>
                        <CTooltip text="Tooltip on left" placement="left">
                            <button class="styleguide-tooltip-trigger">Left</button>
                        </CTooltip>
                        <CTooltip text="Tooltip on right" placement="right">
                            <button class="styleguide-tooltip-trigger">Right</button>
                        </CTooltip>
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Usage Pattern</h2>
                    <p class="styleguide-hint">
                        Envuelve cualquier elemento con <code>c-tooltip</code> y pasa el texto via prop <code>text</code>.
                        Soporta hover y focus. Posicion: <code>top | bottom | left | right</code>.
                    </p>
                </div>
            </div>
        );
    }
});
