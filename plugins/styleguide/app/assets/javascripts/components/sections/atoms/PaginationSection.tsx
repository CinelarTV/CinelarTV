import { defineComponent, ref } from 'vue';
import CPagination from '@/components/CPagination';

export default defineComponent({
    name: 'PaginationSection',
    setup() {
        const page1 = ref(1);
        const page2 = ref(3);
        const page3 = ref(5);

        return () => (
            <div class="styleguide-section">
                <h1 class="styleguide-section__title">Pagination</h1>
                <p class="styleguide-section__description">
                    Componente <code>c-pagination</code> con soporte para ellipsis, compacto y first/last.
                </p>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Default</h2>
                    <CPagination
                        v-model:currentPage={page1.value}
                        totalPages={10}
                    />
                    <p class="styleguide-hint">
                        Pagina <code>{page1.value}</code> de <code>10</code>
                    </p>
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">Compact</h2>
                    <CPagination
                        v-model:currentPage={page2.value}
                        totalPages={10}
                        compact
                    />
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">With First/Last</h2>
                    <CPagination
                        v-model:currentPage={page3.value}
                        totalPages={20}
                        showFirstLast
                    />
                </div>

                <div class="styleguide-subsection">
                    <h2 class="styleguide-subsection__title">More Siblings</h2>
                    <CPagination
                        v-model:currentPage={page3.value}
                        totalPages={20}
                        siblingCount={2}
                    />
                </div>
            </div>
        );
    }
});
