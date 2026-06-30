import { defineComponent } from 'vue';
import { RouterLink, RouterView, useRoute } from 'vue-router';
import StyleguideSidebar from '../components/StyleguideSidebar.tsx';

export default defineComponent({
    name: 'StyleguideView',
    setup() {
        const route = useRoute();

        return () => (
            <div class="styleguide-layout">
                <StyleguideSidebar />
                <main class="styleguide-content">
                    <div class="styleguide-content__inner">
                        <RouterView />
                    </div>
                </main>
            </div>
        );
    }
});
