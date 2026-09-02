import { defineComponent, PropType } from 'vue';

export interface TableColumn {
    key: string;
    label: string;
    sortable?: boolean;
    width?: string;
    align?: 'left' | 'center' | 'right';
}

export default defineComponent({
    name: 'CTable',
    props: {
        columns: {
            type: Array as PropType<TableColumn[]>,
            required: true
        },
        data: {
            type: Array as PropType<Record<string, any>[]>,
            required: true
        },
        striped: {
            type: Boolean,
            default: false
        },
        compact: {
            type: Boolean,
            default: false
        },
        sortKey: {
            type: String,
            default: ''
        },
        sortDir: {
            type: String as PropType<'asc' | 'desc'>,
            default: 'asc'
        },
        loading: {
            type: Boolean,
            default: false
        },
        emptyText: {
            type: String,
            default: 'No data available'
        },
        hoverable: {
            type: Boolean,
            default: true
        }
    },
    emits: ['sort'],
    setup(props, { slots, emit }) {
        const onSort = (key: string) => {
            emit('sort', key);
        };

        const sortIcon = (key: string) => {
            if (props.sortKey !== key) return '↕';
            return props.sortDir === 'asc' ? '↑' : '↓';
        };

        const cellAlign = (col: TableColumn) => {
            if (col.align) return `text-${col.align}`;
            return '';
        };

        return () => (
            <div class="c-table-wrapper">
                <table
                    class={[
                        'c-table',
                        props.striped && 'c-table--striped',
                        props.compact && 'c-table--compact',
                        props.hoverable && 'c-table--hoverable'
                    ]}
                >
                    <thead>
                        <tr>
                            {props.columns.map((col) => (
                                <th
                                    key={col.key}
                                    class={[
                                        col.sortable && 'c-table__th--sortable',
                                        cellAlign(col)
                                    ]}
                                    style={col.width ? { width: col.width } : undefined}
                                    onClick={col.sortable ? () => onSort(col.key) : undefined}
                                >
                                    <span class="c-table__th-content">
                                        {col.label}
                                        {col.sortable && (
                                            <span class="c-table__sort-icon">
                                                {sortIcon(col.key)}
                                            </span>
                                        )}
                                    </span>
                                </th>
                            ))}
                        </tr>
                    </thead>
                    <tbody>
                        {props.data.length === 0 && !props.loading ? (
                            <tr>
                                <td colspan={props.columns.length} class="c-table__empty">
                                    {props.emptyText}
                                </td>
                            </tr>
                        ) : (
                            props.data.map((row, rowIndex) => (
                                <tr key={row.id ?? rowIndex}>
                                    {props.columns.map((col) => (
                                        <td
                                            key={col.key}
                                            class={cellAlign(col)}
                                        >
                                            {slots[`cell-${col.key}`]
                                                ? slots[`cell-${col.key}`]({ row, value: row[col.key] })
                                                : row[col.key]
                                            }
                                        </td>
                                    ))}
                                </tr>
                            ))
                        )}
                        {props.loading && (
                            <tr>
                                <td colspan={props.columns.length} class="c-table__loading">
                                    <div class="c-table__spinner" />
                                </td>
                            </tr>
                        )}
                    </tbody>
                </table>
            </div>
        );
    }
});
