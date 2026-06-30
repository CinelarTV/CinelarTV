import { defineComponent, ref } from 'vue';
import CButton from '@/components/forms/c-button';
import CInput from '@/components/forms/c-input.vue';
import CFormRow from '@/components/forms/CFormRow.tsx';

export default defineComponent({
    name: 'ModalsSection',
    setup() {
        const showModal = ref(false);
        const showSignupModal = ref(false);

        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">Modals</h1>
                <p class="styleguide-section__description">
                    Ventanas modales para login, registro y formularios. Se abren desde la barra de navegación.
                </p>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Login Modal</h2>
                    <div class="styleguide-preview-box">
                        <div class="styleguide-modal-preview">
                            <div class="styleguide-modal-preview__header">
                                <h3>Welcome Back</h3>
                                <button class="styleguide-modal-preview__close">&times;</button>
                            </div>
                            <div class="styleguide-modal-preview__body">
                                <CFormRow label="Email or username">
                                    <CInput placeholder="Email or username" />
                                </CFormRow>
                                <CFormRow label="Password">
                                    <CInput placeholder="Password" type="password" />
                                </CFormRow>
                                <CButton variant="primary" style={{ width: '100%', marginTop: '16px' }}>
                                    Log In
                                </CButton>
                            </div>
                            <div class="styleguide-modal-preview__footer">
                                <span>Don't have an account? <a href="#">Sign up</a></span>
                            </div>
                        </div>
                    </div>
                    <p class="styleguide-hint">
                        Componente: <code>login.modal.tsx</code> — Se activa desde el Header
                    </p>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Signup Modal</h2>
                    <div class="styleguide-preview-box">
                        <div class="styleguide-modal-preview">
                            <div class="styleguide-modal-preview__header">
                                <h3>Create Account</h3>
                                <button class="styleguide-modal-preview__close">&times;</button>
                            </div>
                            <div class="styleguide-modal-preview__body">
                                <CFormRow label="Full name">
                                    <CInput placeholder="Full name" />
                                </CFormRow>
                                <CFormRow label="Email address">
                                    <CInput placeholder="Email address" type="email" />
                                </CFormRow>
                                <CFormRow label="Username">
                                    <CInput placeholder="Username" />
                                </CFormRow>
                                <CFormRow label="Password">
                                    <CInput placeholder="Password" type="password" />
                                </CFormRow>
                                <CButton variant="primary" style={{ width: '100%', marginTop: '16px' }}>
                                    Create Account
                                </CButton>
                            </div>
                            <div class="styleguide-modal-preview__footer">
                                <span>Already have an account? <a href="#">Log in</a></span>
                            </div>
                        </div>
                    </div>
                    <p class="styleguide-hint">
                        Componente: <code>signup.modal.tsx</code> — Se activa desde el Header
                    </p>
                </div>
            </div>
        );
    }
});
