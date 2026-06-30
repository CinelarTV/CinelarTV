import { defineComponent } from 'vue';

export default defineComponent({
    name: 'HeaderSection',
    setup() {
        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">Header</h1>
                <p class="styleguide-section__description">
                    Barra de navegación superior con logo, enlaces de navegación y panel de usuario.
                </p>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Desktop Header</h2>
                    <div class="styleguide-preview-box">
                        <div class="styleguide-header-preview">
                            <div class="styleguide-header-preview__logo">
                                <div class="styleguide-header-preview__logo-placeholder">C</div>
                                <span>CinelarTV</span>
                            </div>
                            <div class="styleguide-header-preview__nav">
                                <a class="styleguide-header-preview__link" href="#">Explorar</a>
                                <a class="styleguide-header-preview__link" href="#">Buscar</a>
                                <a class="styleguide-header-preview__link" href="#">Mi Coleccion</a>
                            </div>
                            <div class="styleguide-header-preview__user">
                                <div class="styleguide-header-preview__avatar">A</div>
                            </div>
                        </div>
                    </div>
                    <p class="styleguide-hint">
                        Componente: <code>SiteHeader.tsx</code> — Se renderiza en <code>App.vue</code>
                    </p>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Mobile Bottom Nav</h2>
                    <div class="styleguide-preview-box" style={{ maxWidth: '375px' }}>
                        <div class="styleguide-bottomnav-preview">
                            <div class="styleguide-bottomnav-preview__item">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <circle cx="11" cy="11" r="8"/>
                                    <line x1="21" y1="21" x2="16.65" y2="16.65"/>
                                </svg>
                                <span>Buscar</span>
                            </div>
                            <div class="styleguide-bottomnav-preview__item styleguide-bottomnav-preview__item--active">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>
                                </svg>
                                <span>Inicio</span>
                            </div>
                            <div class="styleguide-bottomnav-preview__item">
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/>
                                </svg>
                                <span>Coleccion</span>
                            </div>
                        </div>
                    </div>
                    <p class="styleguide-hint">
                        Componente: <code>MobileBottomNav.tsx</code> — Visible solo en dispositivos moviles
                    </p>
                </div>
            </div>
        );
    }
});
