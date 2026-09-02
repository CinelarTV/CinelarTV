import { defineComponent } from 'vue';
import CIcon from '@/components/c-icon.vue';
import { getAllIcons } from '@/lib/IconLibrary';

export default defineComponent({
    name: 'IconsSection',
    setup() {
        const icons = Array.from(getAllIcons()).sort();

        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">Icons</h1>
                <p class="styleguide-section__description">
                    Iconos SVG disponibles usando <code>c-icon</code> con el sprite de Lucide.
                </p>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Sizes</h2>
                    <div class="styleguide-row" style={{ alignItems: 'flex-end' }}>
                        <div class="styleguide-icon-demo">
                            <CIcon icon="star" size={16} />
                            <span>16px</span>
                        </div>
                        <div class="styleguide-icon-demo">
                            <CIcon icon="star" size={20} />
                            <span>20px</span>
                        </div>
                        <div class="styleguide-icon-demo">
                            <CIcon icon="star" size={24} />
                            <span>24px</span>
                        </div>
                        <div class="styleguide-icon-demo">
                            <CIcon icon="star" size={32} />
                            <span>32px</span>
                        </div>
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Icon Catalog</h2>
                    <div class="styleguide-icon-grid">
                        {icons.map(icon => (
                            <div class="styleguide-icon-item" key={icon}>
                                <CIcon icon={icon} size={24} />
                                <span class="styleguide-icon-item__label">{icon}</span>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        );
    }
});
