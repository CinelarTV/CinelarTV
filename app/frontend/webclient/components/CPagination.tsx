import { defineComponent, computed } from 'vue';
import CIcon from './c-icon.vue';

export default defineComponent({
    name: 'CPagination',
    props: {
        currentPage: {
            type: Number,
            required: true
        },
        totalPages: {
            type: Number,
            required: true
        },
        siblingCount: {
            type: Number,
            default: 1
        },
        compact: {
            type: Boolean,
            default: false
        },
        showFirstLast: {
            type: Boolean,
            default: false
        }
    },
    emits: ['update:currentPage'],
    setup(props, { emit }) {
        const goTo = (page: number) => {
            if (page >= 1 && page <= props.totalPages && page !== props.currentPage) {
                emit('update:currentPage', page);
            }
        };

        const visiblePages = computed(() => {
            const pages: (number | string)[] = [];
            const start = Math.max(1, props.currentPage - props.siblingCount);
            const end = Math.min(props.totalPages, props.currentPage + props.siblingCount);

            if (start > 1) {
                pages.push(1);
                if (start > 2) pages.push('...');
            }

            for (let i = start; i <= end; i++) {
                pages.push(i);
            }

            if (end < props.totalPages) {
                if (end < props.totalPages - 1) pages.push('...');
                pages.push(props.totalPages);
            }

            return pages;
        });

        return () => (
            <div class={['c-pagination', props.compact && 'c-pagination--compact']}>
                {props.showFirstLast && (
                    <button
                        class="c-pagination__btn"
                        disabled={props.currentPage === 1}
                        onClick={() => goTo(1)}
                        aria-label="First page"
                    >
                        <CIcon icon="chevrons-left" size={16} />
                    </button>
                )}
                <button
                    class="c-pagination__btn"
                    disabled={props.currentPage === 1}
                    onClick={() => goTo(props.currentPage - 1)}
                    aria-label="Previous page"
                >
                    <CIcon icon="chevron-left" size={16} />
                </button>

                {props.compact ? (
                    <span class="c-pagination__info">
                        {props.currentPage} / {props.totalPages}
                    </span>
                ) : (
                    visiblePages.value.map((page, i) => (
                        typeof page === 'number' ? (
                            <button
                                key={i}
                                class={[
                                    'c-pagination__btn',
                                    props.currentPage === page && 'c-pagination__btn--active'
                                ]}
                                onClick={() => goTo(page)}
                            >
                                {page}
                            </button>
                        ) : (
                            <span key={i} class="c-pagination__ellipsis">{page}</span>
                        )
                    ))
                )}

                <button
                    class="c-pagination__btn"
                    disabled={props.currentPage === props.totalPages}
                    onClick={() => goTo(props.currentPage + 1)}
                    aria-label="Next page"
                >
                    <CIcon icon="chevron-right" size={16} />
                </button>
                {props.showFirstLast && (
                    <button
                        class="c-pagination__btn"
                        disabled={props.currentPage === props.totalPages}
                        onClick={() => goTo(props.totalPages)}
                        aria-label="Last page"
                    >
                        <CIcon icon="chevrons-right" size={16} />
                    </button>
                )}
            </div>
        );
    }
});
