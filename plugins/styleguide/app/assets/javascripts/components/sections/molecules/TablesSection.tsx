import { defineComponent, ref } from 'vue';
import CTable from '@/components/CTable';
import CBadge from '@/components/CBadge';

const mockUsers = [
    { id: 1, name: 'Alice Johnson', email: 'alice@example.com', role: 'Admin', status: 'active', joined: '2024-01-15' },
    { id: 2, name: 'Bob Smith', email: 'bob@example.com', role: 'Editor', status: 'active', joined: '2024-03-22' },
    { id: 3, name: 'Carol White', email: 'carol@example.com', role: 'Viewer', status: 'inactive', joined: '2024-05-10' },
    { id: 4, name: 'David Brown', email: 'david@example.com', role: 'Editor', status: 'active', joined: '2024-07-01' },
    { id: 5, name: 'Eva Martinez', email: 'eva@example.com', role: 'Admin', status: 'active', joined: '2024-09-18' }
];

const columns = [
    { key: 'name', label: 'Name', sortable: true },
    { key: 'email', label: 'Email', sortable: true },
    { key: 'role', label: 'Role' },
    { key: 'status', label: 'Status' },
    { key: 'joined', label: 'Joined', sortable: true }
];

export default defineComponent({
    name: 'TablesSection',
    setup() {
        const sortKey = ref('name');
        const sortDir = ref<'asc' | 'desc'>('asc');

        const onSort = (key: string) => {
            if (sortKey.value === key) {
                sortDir.value = sortDir.value === 'asc' ? 'desc' : 'asc';
            } else {
                sortKey.value = key;
                sortDir.value = 'asc';
            }
        };

        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">Tables</h1>
                <p class="styleguide-section__description">
                    Componente <code>c-table</code> con columnas ordenables, variantes de filas y estados vacios.
                </p>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Default</h2>
                    <CTable
                        columns={columns}
                        data={mockUsers}
                        sortKey={sortKey.value}
                        sortDir={sortDir.value}
                        onSort={onSort}
                    />
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Striped</h2>
                    <CTable columns={columns} data={mockUsers} striped />
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Compact</h2>
                    <CTable columns={columns} data={mockUsers} compact />
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Custom Cell Rendering</h2>
                    <CTable columns={columns} data={mockUsers}>
                        {{
                            'cell-status': ({ value }: { value: string }) => (
                                <CBadge variant={value === 'active' ? 'success' : 'muted'}>
                                    {value}
                                </CBadge>
                            )
                        }}
                    </CTable>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Empty State</h2>
                    <CTable columns={columns} data={[]} emptyText="No users found" />
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Loading</h2>
                    <CTable columns={columns} data={[]} loading />
                </div>
            </div>
        );
    }
});
