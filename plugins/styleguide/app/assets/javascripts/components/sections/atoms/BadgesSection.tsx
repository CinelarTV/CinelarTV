import { defineComponent } from 'vue';
import CBadge from '@/components/CBadge';

export default defineComponent({
    name: 'BadgesSection',
    setup() {
        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">Badges</h1>
                <p class="styleguide-section__description">
                    Componente <code>c-badge</code> para etiquetas de estado, categorias y cantidades.
                </p>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Variants</h2>
                    <div class="styleguide-row">
                        <CBadge>Default</CBadge>
                        <CBadge variant="primary">Primary</CBadge>
                        <CBadge variant="success">Success</CBadge>
                        <CBadge variant="warning">Warning</CBadge>
                        <CBadge variant="danger">Danger</CBadge>
                        <CBadge variant="info">Info</CBadge>
                        <CBadge variant="muted">Muted</CBadge>
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Pill</h2>
                    <div class="styleguide-row">
                        <CBadge pill>Default</CBadge>
                        <CBadge variant="primary" pill>Primary</CBadge>
                        <CBadge variant="success" pill>Success</CBadge>
                        <CBadge variant="warning" pill>Warning</CBadge>
                        <CBadge variant="danger" pill>Danger</CBadge>
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">With Dot</h2>
                    <div class="styleguide-row">
                        <CBadge variant="success" dot>Online</CBadge>
                        <CBadge variant="danger" dot>Offline</CBadge>
                        <CBadge variant="warning" dot>Away</CBadge>
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Sizes</h2>
                    <div class="styleguide-row" style={{ alignItems: 'center' }}>
                        <CBadge variant="primary" size="sm">Small</CBadge>
                        <CBadge variant="primary">Default</CBadge>
                        <CBadge variant="primary" size="lg">Large</CBadge>
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Bordered</h2>
                    <div class="styleguide-row">
                        <CBadge variant="primary" bordered>Bordered</CBadge>
                        <CBadge variant="success" bordered pill>Pill Bordered</CBadge>
                    </div>
                </div>
            </div>
        );
    }
});
