import { defineComponent, ref } from 'vue';
import CAlert from '@/components/CAlert';

export default defineComponent({
    name: 'AlertsSection',
    setup() {
        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">Alerts</h1>
                <p class="styleguide-section__description">
                    Componente <code>c-alert</code> para notificaciones inline con variantes de color y cierre.
                </p>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Variants</h2>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                        <CAlert type="info" title="Information">
                            This is an informational alert message.
                        </CAlert>
                        <CAlert type="success" title="Success">
                            Operation completed successfully.
                        </CAlert>
                        <CAlert type="warning" title="Warning">
                            Please review this action before continuing.
                        </CAlert>
                        <CAlert type="danger" title="Error">
                            Something went wrong. Please try again.
                        </CAlert>
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Dismissible</h2>
                    <CAlert type="info" title="Tip" dismissible>
                        This alert can be dismissed by clicking the close button.
                    </CAlert>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Without Title</h2>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                        <CAlert type="success">Your profile has been updated.</CAlert>
                        <CAlert type="danger">Session expired. Please log in again.</CAlert>
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Borderless</h2>
                    <CAlert type="warning" borderless>
                        A borderless alert for subtle notifications.
                    </CAlert>
                </div>
            </div>
        );
    }
});
