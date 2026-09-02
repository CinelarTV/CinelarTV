import { defineComponent, ref } from 'vue';
import CDropdown from '@/components/CDropdown';
import CButton from '@/components/forms/c-button';
import type { DropdownItem } from '@/components/CDropdown';

const actionItems: DropdownItem[] = [
    { key: 'edit', label: 'Edit', icon: 'edit' },
    { key: 'duplicate', label: 'Duplicate', icon: 'copy' },
    { key: 'sep', separator: true },
    { key: 'delete', label: 'Delete', icon: 'trash', danger: true }
];

const filterItems: DropdownItem[] = [
    { key: 'type-header', label: 'Type', header: true },
    { key: 'movies', label: 'Movies', icon: 'film' },
    { key: 'series', label: 'Series', icon: 'tv' },
    { key: 'docs', label: 'Documentaries', icon: 'book-open' },
    { key: 'sep', separator: true },
    { key: 'status-header', label: 'Status', header: true },
    { key: 'published', label: 'Published', icon: 'check-circle' },
    { key: 'draft', label: 'Draft', icon: 'file-text' }
];

const userItems: DropdownItem[] = [
    { key: 'profile', label: 'Profile', icon: 'user' },
    { key: 'settings', label: 'Settings', icon: 'settings' },
    { key: 'billing', label: 'Billing', icon: 'credit-card' },
    { key: 'sep', separator: true },
    { key: 'logout', label: 'Log out', icon: 'log-out', danger: true }
];

export default defineComponent({
    name: 'DropdownsSection',
    setup() {
        const lastSelected = ref('');

        const onSelect = (item: DropdownItem) => {
            lastSelected.value = item.label || item.key;
        };

        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">Dropdowns</h1>
                <p class="styleguide-section__description">
                    Componente <code>c-dropdown</code> para menus desplegables con acciones y headers.
                </p>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Simple Actions</h2>
                    <CDropdown items={actionItems} onSelect={onSelect}>
                        {{
                            trigger: () => <CButton icon="chevron-down">Actions</CButton>
                        }}
                    </CDropdown>
                    {lastSelected.value && (
                        <p class="styleguide-hint">Last selected: <code>{lastSelected.value}</code></p>
                    )}
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">With Headers</h2>
                    <CDropdown items={filterItems} onSelect={onSelect}>
                        {{
                            trigger: () => <CButton variant="ghost" icon="chevron-down">Filter by</CButton>
                        }}
                    </CDropdown>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Right-aligned</h2>
                    <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
                        <CDropdown items={actionItems} placement="right" onSelect={onSelect}>
                            {{
                                trigger: () => <CButton variant="ghost" icon="more-vertical" />
                            }}
                        </CDropdown>
                    </div>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">User Menu</h2>
                    <CDropdown items={userItems} width="200px" onSelect={onSelect}>
                        {{
                            trigger: () => (
                                <div class="styleguide-header-preview__avatar" style={{ cursor: 'pointer' }}>AJ</div>
                            )
                        }}
                    </CDropdown>
                </div>
            </div>
        );
    }
});
