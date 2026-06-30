import { defineComponent, ref } from 'vue';
import { RouterLink, useRoute } from 'vue-router';

interface SidebarSection {
    label: string;
    routeName: string;
}

interface SidebarCategory {
    label: string;
    sections: SidebarSection[];
}

const categories: SidebarCategory[] = [
    {
        label: 'Atoms',
        sections: [
            { label: 'Buttons', routeName: 'styleguide.atoms.buttons' },
            { label: 'Inputs', routeName: 'styleguide.atoms.inputs' },
            { label: 'Icons', routeName: 'styleguide.atoms.icons' },
            { label: 'Spinners', routeName: 'styleguide.atoms.spinners' },
            { label: 'Colors', routeName: 'styleguide.atoms.colors' },
            { label: 'Typography', routeName: 'styleguide.atoms.typography' },
            { label: 'Uploaders', routeName: 'styleguide.atoms.uploaders' }
        ]
    },
    {
        label: 'Molecules',
        sections: [
            { label: 'ContentCard', routeName: 'styleguide.molecules.content-card' },
            { label: 'ContentRow', routeName: 'styleguide.molecules.content-row' },
            { label: 'Forms', routeName: 'styleguide.molecules.forms' }
        ]
    },
    {
        label: 'Organisms',
        sections: [
            { label: 'Header', routeName: 'styleguide.organisms.header' },
            { label: 'Modals', routeName: 'styleguide.organisms.modals' }
        ]
    }
];

export default defineComponent({
    name: 'StyleguideSidebar',
    setup() {
        const route = useRoute();
        const expandedCategories = ref<Set<string>>(new Set(['Atoms', 'Molecules', 'Organisms']));

        const toggleCategory = (label: string) => {
            if (expandedCategories.value.has(label)) {
                expandedCategories.value.delete(label);
            } else {
                expandedCategories.value.add(label);
            }
        };

        const isActive = (routeName: string) => {
            return route.name === routeName;
        };

        return () => (
            <aside class="styleguide-sidebar">
                <div class="styleguide-sidebar__header">
                    <RouterLink to="/styleguide" class="styleguide-sidebar__title">
                        Styleguide
                    </RouterLink>
                </div>
                <nav class="styleguide-sidebar__nav">
                    {categories.map(category => (
                        <div class="styleguide-sidebar__category" key={category.label}>
                            <button
                                class="styleguide-sidebar__category-toggle"
                                onClick={() => toggleCategory(category.label)}
                            >
                                <span class="styleguide-sidebar__category-label">
                                    {category.label}
                                </span>
                                <svg
                                    class={`styleguide-sidebar__chevron ${expandedCategories.value.has(category.label) ? 'styleguide-sidebar__chevron--open' : ''}`}
                                    width="12"
                                    height="12"
                                    viewBox="0 0 12 12"
                                    fill="none"
                                >
                                    <path d="M4 2L8 6L4 10" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                                </svg>
                            </button>
                            {expandedCategories.value.has(category.label) && (
                                <ul class="styleguide-sidebar__sections">
                                    {category.sections.map(section => (
                                        <li key={section.routeName}>
                                            <RouterLink
                                                to={{ name: section.routeName }}
                                                class={`styleguide-sidebar__link ${isActive(section.routeName) ? 'styleguide-sidebar__link--active' : ''}`}
                                            >
                                                {section.label}
                                            </RouterLink>
                                        </li>
                                    ))}
                                </ul>
                            )}
                        </div>
                    ))}
                </nav>
            </aside>
        );
    }
});
