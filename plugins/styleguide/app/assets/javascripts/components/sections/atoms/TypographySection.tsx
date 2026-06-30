import { defineComponent } from 'vue';

export default defineComponent({
    name: 'TypographySection',
    setup() {
        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">Typography</h1>
                <p class="styleguide-section__description">
                    Estilos de tipografía y tamaños de fuente del sistema.
                </p>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Headings</h2>
                    <div class="styleguide-typography-list">
                        <div class="styleguide-typography-item">
                            <h1 style={{ margin: 0 }}>Heading 1</h1>
                            <code>h1 - 2.25rem / bold</code>
                        </div>
                        <div class="styleguide-typography-item">
                            <h2 style={{ margin: 0 }}>Heading 2</h2>
                            <code>h2 - 1.875rem / bold</code>
                        </div>
                        <div class="styleguide-typography-item">
                            <h3 style={{ margin: 0 }}>Heading 3</h3>
                            <code>h3 - 1.5rem / semibold</code>
                        </div>
                        <div class="styleguide-typography-item">
                            <h4 style={{ margin: 0 }}>Heading 4</h4>
                            <code>h4 - 1.25rem / semibold</code>
                        </div>
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Body Text</h2>
                    <div class="styleguide-typography-list">
                        <div class="styleguide-typography-item">
                            <p style={{ margin: 0, fontSize: '1rem' }}>
                                Lorem ipsum dolor sit amet, consectetur adipiscing elit.
                            </p>
                            <code>Normal - 1rem</code>
                        </div>
                        <div class="styleguide-typography-item">
                            <p style={{ margin: 0, fontSize: '0.875rem' }}>
                                Lorem ipsum dolor sit amet, consectetur adipiscing elit.
                            </p>
                            <code>Small - 0.875rem</code>
                        </div>
                        <div class="styleguide-typography-item">
                            <p style={{ margin: 0, fontSize: '0.75rem' }}>
                                Lorem ipsum dolor sit amet, consectetur adipiscing elit.
                            </p>
                            <code>Extra Small - 0.75rem</code>
                        </div>
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Font Weights</h2>
                    <div class="styleguide-typography-list">
                        <div class="styleguide-typography-item">
                            <p style={{ margin: 0, fontWeight: 400 }}>Regular weight text</p>
                            <code>font-weight: 400 (regular)</code>
                        </div>
                        <div class="styleguide-typography-item">
                            <p style={{ margin: 0, fontWeight: 500 }}>Medium weight text</p>
                            <code>font-weight: 500 (medium)</code>
                        </div>
                        <div class="styleguide-typography-item">
                            <p style={{ margin: 0, fontWeight: 600 }}>Semibold weight text</p>
                            <code>font-weight: 600 (semibold)</code>
                        </div>
                        <div class="styleguide-typography-item">
                            <p style={{ margin: 0, fontWeight: 700 }}>Bold weight text</p>
                            <code>font-weight: 700 (bold)</code>
                        </div>
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Code</h2>
                    <div class="styleguide-typography-list">
                        <div class="styleguide-typography-item">
                            <code style={{ fontSize: '1rem' }}>inline code element</code>
                            <code>code element</code>
                        </div>
                        <div class="styleguide-typography-item">
                            <pre style={{ margin: 0, padding: '12px', background: 'rgba(255,255,255,0.05)', borderRadius: '8px' }}>preformatted text block</pre>
                            <code>pre element</code>
                        </div>
                    </div>
                </div>
            </div>
        );
    }
});
