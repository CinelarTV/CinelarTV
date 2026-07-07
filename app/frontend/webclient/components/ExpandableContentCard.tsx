import { defineComponent, ref, computed, PropType, onUnmounted, watch, h, render, nextTick } from 'vue';
import { RouterLink } from 'vue-router';

interface ContentItem {
    id: number | string;
    title: string;
    description?: string;
    banner: string;
    poster?: string;
    year?: number;
    rating?: string;
    genres?: string[];
    duration?: number;
    progress?: number;
    isNew?: boolean;
}

const PORTAL_ID = 'ctv-portal';

function getOrCreatePortal(): HTMLElement {
    let el = document.getElementById(PORTAL_ID);
    if (!el) {
        el = document.createElement('div');
        el.id = PORTAL_ID;
        document.body.appendChild(el);
    }
    return el;
}

export default defineComponent({
    name: 'ExpandableContentCard',
    emits: ['expand', 'close'],
    props: {
        item: {
            type: Object as PropType<ContentItem>,
            required: true,
        },
        itemType: {
            type: String as PropType<'landscape' | 'portrait'>,
            default: 'landscape',
        },
        expanded: {
            type: Boolean,
            default: false,
        },
    },
    setup(props, { emit }) {
        const hoverTimeout = ref<number | null>(null);
        const closeTimeout = ref<number | null>(null);
        const cardRef = ref<HTMLElement | null>(null);
        const panelPosition = ref({ top: 0, left: 0, width: 0 });
        const portalRef = ref<HTMLElement | null>(null);
        let panelVNode: ReturnType<typeof h> | null = null;

        const cardWidth = computed(() =>
            props.itemType === 'portrait'
                ? 'w-[100px] sm:w-[120px] md:w-[140px] lg:w-[160px]'
                : 'w-[180px] sm:w-[220px] md:w-[260px] lg:w-[300px]'
        );
        const aspectRatio = computed(() =>
            props.itemType === 'portrait' ? 'aspect-[2/3]' : 'aspect-video'
        );

        const progressPercent = computed(() => {
            if (!props.item.progress || !props.item.duration) return 0;
            return Math.min(100, Math.round((props.item.progress / props.item.duration) * 100));
        });

        const panelWidth = computed(() => {
            if (!cardRef.value) return 300;
            const rect = cardRef.value.getBoundingClientRect();
            const pw = rect.width * 1.5;
            const viewportWidth = window.innerWidth;
            return Math.min(pw, viewportWidth - 16);
        });

        const updatePanelPosition = () => {
            if (!cardRef.value) return;
            const rect = cardRef.value.getBoundingClientRect();
            const pw = panelWidth.value;
            const viewportWidth = window.innerWidth;

            let left = rect.left + (rect.width - pw) / 2;
            if (left < 8) left = 8;
            else if (left + pw > viewportWidth - 8) left = viewportWidth - pw - 8;

            panelPosition.value = { top: rect.bottom + 4, left, width: pw };
        };

        const formatDuration = (seconds: number): string => {
            const h = Math.floor(seconds / 3600);
            const m = Math.floor((seconds / 60) % 60);
            if (h > 0) return `${h}h ${m}m`;
            return `${m}m`;
        };

        const cancelClose = () => {
            if (closeTimeout.value) {
                clearTimeout(closeTimeout.value);
                closeTimeout.value = null;
            }
        };

        const scheduleClose = () => {
            cancelClose();
            closeTimeout.value = window.setTimeout(() => {
                emit('close', props.item.id);
                closeTimeout.value = null;
            }, 350);
        };

        const handleDocumentClick = (e: MouseEvent) => {
            const target = e.target as HTMLElement;
            if (!target.closest('[data-expand-panel]') && !target.closest('.expandable-card')) {
                emit('close', props.item.id);
            }
        };

        const renderPanel = () => {
            const item = props.item;
            const pos = panelPosition.value;

            return h('div', [
                h('div', {
                    class: [
                        'expanded-panel',
                        'fixed z-[1000]',
                        'bg-[#181818]',
                        'rounded-xl',
                        'overflow-hidden',
                        'shadow-[0_16px_48px_rgba(0,0,0,0.9)]',
                        'border border-white/10',
                        'animate-expand-down',
                    ],
                    style: {
                        top: `${pos.top}px`,
                        left: `${pos.left}px`,
                        width: `${pos.width}px`,
                    },
                    'data-expand-panel': 'true',
                    onMouseenter: () => cancelClose(),
                    onMouseleave: () => scheduleClose(),
                    onClick: (e: MouseEvent) => e.stopPropagation(),
                }, [
                    h('div', { class: 'relative' }, [
                        h('img', {
                            src: item.banner,
                            alt: item.title,
                            class: 'w-full aspect-video object-cover',
                        }),
                        h('div', {
                            class: 'absolute inset-0 bg-gradient-to-t from-[#181818] via-[#181818]/60 to-transparent',
                        }),
                        h('button', {
                            class: [
                                'absolute top-3 right-3',
                                'w-8 h-8 rounded-full',
                                'bg-black/60 hover:bg-black/80',
                                'border border-white/20',
                                'flex items-center justify-center',
                                'text-white/80 hover:text-white',
                                'transition-all duration-150',
                            ],
                            onClick: (e: MouseEvent) => {
                                e.stopPropagation();
                                emit('close', item.id);
                            },
                            'aria-label': 'Cerrar',
                        }, [
                            h('svg', {
                                width: 14, height: 14,
                                viewBox: '0 0 24 24',
                                fill: 'none', stroke: 'currentColor',
                                'stroke-width': 2.5,
                                'stroke-linecap': 'round',
                            }, [
                                h('line', { x1: 18, y1: 6, x2: 6, y2: 18 }),
                                h('line', { x1: 6, y1: 6, x2: 18, y2: 18 }),
                            ]),
                        ]),
                        h('div', {
                            class: 'absolute bottom-3 left-4 right-4',
                        }, [
                            h('p', {
                                class: 'text-sm font-semibold text-white leading-snug line-clamp-2 mb-2',
                            }, item.title),
                            h('div', { class: 'flex items-center gap-2' }, [
                                h('button', {
                                    class: [
                                        'flex items-center justify-center gap-1.5',
                                        'px-4 py-1.5 rounded-md',
                                        'bg-white hover:bg-white/90',
                                        'text-black text-xs font-semibold',
                                        'transition-colors duration-150',
                                    ],
                                    onClick: (e: MouseEvent) => {
                                        e.preventDefault();
                                        e.stopPropagation();
                                    },
                                }, [
                                    h('svg', {
                                        width: 12, height: 12,
                                        viewBox: '0 0 24 24',
                                        fill: 'black', stroke: 'none',
                                    }, [
                                        h('polygon', { points: '5 3 19 12 5 21 5 3' }),
                                    ]),
                                    'Reproducir',
                                ]),
                                h('button', {
                                    class: [
                                        'flex items-center justify-center',
                                        'w-8 h-8 rounded-full',
                                        'border-2 border-white/40 hover:border-white',
                                        'text-white/70 hover:text-white',
                                        'transition-all duration-150',
                                    ],
                                    onClick: (e: MouseEvent) => {
                                        e.preventDefault();
                                        e.stopPropagation();
                                    },
                                    'aria-label': 'Agregar a mi lista',
                                }, [
                                    h('svg', {
                                        width: 14, height: 14,
                                        viewBox: '0 0 24 24',
                                        fill: 'none', stroke: 'currentColor',
                                        'stroke-width': 2.5,
                                        'stroke-linecap': 'round',
                                    }, [
                                        h('line', { x1: 12, y1: 5, x2: 12, y2: 19 }),
                                        h('line', { x1: 5, y1: 12, x2: 19, y2: 12 }),
                                    ]),
                                ]),
                                h('button', {
                                    class: [
                                        'flex items-center justify-center',
                                        'w-8 h-8 rounded-full',
                                        'border-2 border-white/40 hover:border-white',
                                        'text-white/70 hover:text-white',
                                        'transition-all duration-150',
                                    ],
                                    onClick: (e: MouseEvent) => {
                                        e.preventDefault();
                                        e.stopPropagation();
                                    },
                                    'aria-label': 'No me gusta',
                                }, [
                                    h('svg', {
                                        width: 14, height: 14,
                                        viewBox: '0 0 24 24',
                                        fill: 'none', stroke: 'currentColor',
                                        'stroke-width': 2.5,
                                        'stroke-linecap': 'round',
                                        'stroke-linejoin': 'round',
                                    }, [
                                        h('path', {
                                            d: 'M10 15v4a3 3 0 0 0 3 3l4-9V2H5.72a2 2 0 0 0-2 1.7l-1.38 9a2 2 0 0 0 2 2.3zm7-13h2.67A2.31 2.31 0 0 1 22 4v7a2.31 2.31 0 0 1-2.33 2H17',
                                        }),
                                    ]),
                                ]),
                            ]),
                        ]),
                    ]),
                    h('div', { class: 'px-4 py-3' }, [
                        h('div', { class: 'flex items-center gap-2 text-xs mb-1.5 flex-wrap' }, [
                            item.rating
                                ? h('span', { class: 'text-green-400 font-semibold' }, item.rating)
                                : null,
                            item.year
                                ? h('span', { class: 'text-white/60' }, String(item.year))
                                : null,
                            item.duration
                                ? h('span', { class: 'text-white/60' }, formatDuration(item.duration))
                                : null,
                            item.progress && item.duration
                                ? h('span', { class: 'text-white/40' }, `${progressPercent.value}% visto`)
                                : null,
                        ]),
                        item.genres && item.genres.length > 0
                            ? h('p', {
                                class: 'text-[11px] text-white/40 line-clamp-1',
                            }, item.genres.join(' · '))
                            : null,
                    ]),
                ]),
            ]);
        };

        const updatePortal = async () => {
            await nextTick();
            if (props.expanded && cardRef.value) {
                cancelClose();
                updatePanelPosition();
                if (!portalRef.value) {
                    portalRef.value = getOrCreatePortal();
                }
                panelVNode = renderPanel();
                render(panelVNode, portalRef.value);

                window.addEventListener('scroll', updatePanelPosition, true);
                window.addEventListener('resize', updatePanelPosition);
                document.addEventListener('click', handleDocumentClick, true);
            } else {
                if (portalRef.value) {
                    render(null, portalRef.value);
                }
                panelVNode = null;
                window.removeEventListener('scroll', updatePanelPosition, true);
                window.removeEventListener('resize', updatePanelPosition);
                document.removeEventListener('click', handleDocumentClick, true);
            }
        };

        watch(() => props.expanded, updatePortal);

        const handleMouseEnter = () => {
            cancelClose();
            if (props.expanded) return;
            hoverTimeout.value = window.setTimeout(() => {
                emit('expand', props.item.id);
            }, 250);
        };

        const handleMouseLeave = () => {
            if (hoverTimeout.value) {
                clearTimeout(hoverTimeout.value);
                hoverTimeout.value = null;
            }
            if (!props.expanded) return;
            scheduleClose();
        };

        onUnmounted(() => {
            if (hoverTimeout.value) clearTimeout(hoverTimeout.value);
            if (closeTimeout.value) clearTimeout(closeTimeout.value);
            window.removeEventListener('scroll', updatePanelPosition, true);
            window.removeEventListener('resize', updatePanelPosition);
            document.removeEventListener('click', handleDocumentClick, true);
            if (portalRef.value) {
                render(null, portalRef.value);
                if (portalRef.value.childNodes.length === 0) {
                    portalRef.value.remove();
                }
                portalRef.value = null;
            }
            panelVNode = null;
        });

        return () => (
            <div
                ref={cardRef}
                class={[
                    'expandable-card',
                    'relative',
                    'flex-shrink-0',
                    'snap-start',
                    cardWidth.value,
                    aspectRatio.value,
                ]}
                onMouseenter={handleMouseEnter}
                onMouseleave={handleMouseLeave}
                style={{ zIndex: props.expanded ? 1001 : 1 }}
            >
                <RouterLink
                    to={`/contents/${props.item.id}`}
                    class={[
                        'card-inner',
                        'relative',
                        'w-full',
                        'h-full',
                        'block',
                        'rounded-lg',
                        'overflow-hidden',
                        'transition-all',
                        'duration-300',
                        'ease-out',
                        'bg-white/5',
                        'border',
                        'border-white/[0.06]',
                        {
                            'scale-[1.04]': props.expanded,
                            'hover:scale-[1.04]': !props.expanded,
                            'hover:border-white/20': !props.expanded,
                            'hover:shadow-[0_8px_30px_rgba(0,0,0,0.5)]': !props.expanded,
                            'border-white/20': props.expanded,
                            'shadow-[0_12px_40px_rgba(0,0,0,0.7)]': props.expanded,
                        },
                    ]}
                >
                    <img
                        src={props.item.banner}
                        alt={props.item.title}
                        class="w-full h-full object-cover"
                        loading="lazy"
                    />

                    <div
                        class={[
                            'overlay',
                            'absolute',
                            'inset-0',
                            'bg-gradient-to-t',
                            'from-black/90',
                            'via-black/10',
                            'to-transparent',
                            'flex',
                            'flex-col',
                            'justify-end',
                            'p-3',
                            'transition-opacity',
                            'duration-200',
                            {
                                'opacity-0': props.expanded,
                                'opacity-100': !props.expanded,
                            },
                        ]}
                    >
                        <p class="text-[11px] font-medium text-white leading-tight line-clamp-2">
                            {props.item.title}
                        </p>
                        {(props.item.year || props.item.rating) && (
                            <p class="text-[10px] text-white/60 mt-1">
                                {props.item.year && <span>{props.item.year}</span>}
                                {props.item.year && props.item.rating && <span> · </span>}
                                {props.item.rating && <span>{props.item.rating}</span>}
                                {props.item.progress && props.item.duration && (
                                    <span> · {progressPercent.value}% visto</span>
                                )}
                            </p>
                        )}
                    </div>

                    {props.item.progress && props.item.duration && (
                        <div class="absolute bottom-0 left-0 right-0 h-[2px] bg-white/15">
                            <div
                                class="h-full bg-[#0095d9]"
                                style={{ width: `${progressPercent.value}%` }}
                            />
                        </div>
                    )}

                    {props.item.isNew && (
                        <div class="absolute top-2 left-2">
                            <span class="text-[9px] font-medium px-1.5 py-0.5 rounded bg-white/15 text-white border border-white/25 backdrop-blur-sm leading-none">
                                NUEVO
                            </span>
                        </div>
                    )}
                </RouterLink>
            </div>
        );
    },
});
