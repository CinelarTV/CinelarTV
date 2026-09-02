import { defineComponent, ref } from 'vue';
import CTabs from '@/components/CTabs';

const basicTabs = [
    { key: 'overview', label: 'Overview' },
    { key: 'details', label: 'Details' },
    { key: 'settings', label: 'Settings' }
];

const tabsWithIcons = [
    { key: 'home', label: 'Home', icon: 'home' },
    { key: 'search', label: 'Search', icon: 'search' },
    { key: 'bookmarks', label: 'Bookmarks', icon: 'bookmark' },
    { key: 'profile', label: 'Profile', icon: 'user' }
];

export default defineComponent({
    name: 'TabsSection',
    setup() {
        const activeBasic = ref('overview');
        const activeIcon = ref('home');
        const activePills = ref('all');

        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">Tabs</h1>
                <p class="styleguide-section__description">
                    Componente <code>c-tabs</code> con soporte para variantes default, pills e iconos.
                </p>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Default</h2>
                    <CTabs items={basicTabs} v-model={activeBasic.value}>
                        <p>Content for: <strong>{activeBasic.value}</strong></p>
                    </CTabs>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">With Icons</h2>
                    <CTabs items={tabsWithIcons} v-model={activeIcon.value}>
                        <p>Active tab: <strong>{activeIcon.value}</strong></p>
                    </CTabs>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Pills</h2>
                    <CTabs
                        items={[
                            { key: 'all', label: 'All' },
                            { key: 'movies', label: 'Movies' },
                            { key: 'series', label: 'Series' },
                            { key: 'docs', label: 'Documentaries' }
                        ]}
                        variant="pills"
                        v-model={activePills.value}
                    >
                        <p>Filter: <strong>{activePills.value}</strong></p>
                    </CTabs>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Disabled Tab</h2>
                    <CTabs
                        items={[
                            { key: 'active', label: 'Active' },
                            { key: 'disabled', label: 'Disabled', disabled: true },
                            { key: 'normal', label: 'Normal' }
                        ]}
                        v-model={activeBasic.value}
                    />
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Underline</h2>
                    <CTabs
                        items={[
                            { key: 'tab1', label: 'General' },
                            { key: 'tab2', label: 'Security' },
                            { key: 'tab3', label: 'Notifications' }
                        ]}
                        variant="underline"
                        v-model={activeBasic.value}
                    >
                        <p>Underline variant: <strong>{activeBasic.value}</strong></p>
                    </CTabs>
                </div>
            </div>
        );
    }
});
