import { defineComponent } from 'vue';
import CSkeleton from '@/components/CSkeleton';

export default defineComponent({
    name: 'SkeletonsSection',
    setup() {
        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">Skeletons</h1>
                <p class="styleguide-section__description">
                    Componente <code>c-skeleton</code> para placeholders de carga animados.
                </p>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Text</h2>
                    <CSkeleton variant="text" />
                    <CSkeleton variant="text" width="80%" />
                    <CSkeleton variant="text" width="60%" />
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Circle</h2>
                    <div class="styleguide-row">
                        <CSkeleton variant="circle" width="32px" height="32px" />
                        <CSkeleton variant="circle" width="48px" height="48px" />
                        <CSkeleton variant="circle" width="64px" height="64px" />
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Rectangle</h2>
                    <div class="styleguide-row">
                        <CSkeleton variant="rect" width="120px" height="80px" />
                        <CSkeleton variant="rect" width="120px" height="160px" />
                        <CSkeleton variant="rect" width="200px" height="120px" />
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Card</h2>
                    <div style={{ maxWidth: '300px' }}>
                        <CSkeleton variant="card" />
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Avatar + Text</h2>
                    <div style={{ maxWidth: '400px' }}>
                        <CSkeleton variant="avatar-text" />
                        <CSkeleton variant="avatar-text" />
                        <CSkeleton variant="avatar-text" />
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Non-animated</h2>
                    <CSkeleton variant="text" animated={false} />
                    <CSkeleton variant="text" width="70%" animated={false} />
                </div>
            </div>
        );
    }
});
