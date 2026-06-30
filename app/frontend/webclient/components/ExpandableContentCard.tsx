import { defineComponent, ref, computed, PropType, onUnmounted, Teleport } from 'vue';
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
    isPrime?: boolean;
    isNew?: boolean;
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
        const cardRef = ref<HTMLElement | null>(null);
        const panelPosition = ref({ top: 0, left: 0, width: 0 });

        const cardWidth = computed(() => props.itemType === 'portrait' ? 'w-[100px] sm:w-[120px] md:w-[140px] lg:w-[160px]' : 'w-[180px] sm:w-[220px] md:w-[260px] lg:w-[300px]');
        const aspectRatio = computed(() => props.itemType === 'portrait' ? 'aspect-[2/3]' : 'aspect-video');

        const progressPercent = computed(() => {
            if (!props.item.progress || !props.item.duration) return 0;
            return Math.min(100, Math.round((props.item.progress / props.item.duration) * 100));
        });

        const updatePanelPosition = () => {
            if (cardRef.value) {
                const rect = cardRef.value.getBoundingClientRect();
                const panelWidth = rect.width * 1.04;
                const viewportWidth = window.innerWidth;

                let left = rect.left + (rect.width - panelWidth) / 2;
                if (left < 8) {
                    left = 8;
                } else if (left + panelWidth > viewportWidth - 8) {
                    left = viewportWidth - panelWidth - 8;
                }

                panelPosition.value = {
                    top: rect.bottom + 2,
                    left,
                    width: panelWidth,
                };
            }
        };

        const handleMouseEnter = () => {
            hoverTimeout.value = window.setTimeout(() => {
                updatePanelPosition();
                emit('expand', props.item.id);
                // Listen to all scroll events (capture phase) to track scroll within containers
                window.addEventListener('scroll', updatePanelPosition, true);
                window.addEventListener('resize', updatePanelPosition);
            }, 250);
        };

        const handleMouseLeave = () => {
            if (hoverTimeout.value) {
                clearTimeout(hoverTimeout.value);
                hoverTimeout.value = null;
            }
            emit('close', props.item.id);
            window.removeEventListener('scroll', updatePanelPosition, true);
            window.removeEventListener('resize', updatePanelPosition);
        };

        const truncateGenres = (genres: string[], maxLength: number = 60): string => {
            const genreString = genres.join(' • ');
            return genreString.length > maxLength ? genreString.substring(0, maxLength) + '...' : genreString;
        };

        onUnmounted(() => {
            if (hoverTimeout.value) {
                clearTimeout(hoverTimeout.value);
            }
            window.removeEventListener('scroll', updatePanelPosition, true);
            window.removeEventListener('resize', updatePanelPosition);
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
                style={{
                    zIndex: props.expanded ? 50 : 1,
                }}
            >
                {/* RouterLink wrapper - card only */}
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
                    {/* Thumbnail */}
                    <img
                        src={props.item.banner}
                        alt={props.item.title}
                        class="w-full h-full object-cover"
                        loading="lazy"
                    />

                    {/* Simple hover overlay (non-expanded state) */}
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
                                {props.item.progress && props.item.duration && <span> · {progressPercent.value}% visto</span>}
                            </p>
                        )}
                    </div>

                    {/* Progress bar */}
                    {props.item.progress && props.item.duration && (
                        <div class="absolute bottom-0 left-0 right-0 h-[2px] bg-white/15">
                            <div
                                class="h-full bg-[#0095d9]"
                                style={{ width: `${progressPercent.value}%` }}
                            />
                        </div>
                    )}

                    {/* Badges */}
                    <div class="absolute top-2 left-2 flex gap-1">
                        {props.item.isNew && (
                            <span class="text-[9px] font-medium px-1.5 py-0.5 rounded bg-white/15 text-white border border-white/25 backdrop-blur-sm leading-none">
                                NUEVO
                            </span>
                        )}
                        {!props.item.isNew && props.item.isPrime !== false && (
                            <span class="text-[9px] font-medium px-1.5 py-0.5 rounded bg-[#0095d9] text-white leading-none">
                                PRIME
                            </span>
                        )}
                    </div>
                </RouterLink>

                {/* Expanded panel via Teleport - rendered in body to escape scroll container */}
                <Teleport to="body">
                    {props.expanded && (
                        <div
                            class={[
                                'expanded-panel',
                                'absolute',
                                'bg-[#181818]',
                                'rounded-b-lg',
                                'overflow-hidden',
                                'shadow-[0_12px_40px_rgba(0,0,0,0.9)]',
                                'border',
                                'border-white/10',
                                'border-t-0',
                                'animate-expand-down',
                            ]}
                            style={{
                                position: 'fixed',
                                top: `${panelPosition.value.top}px`,
                                left: `${panelPosition.value.left}px`,
                                width: `${panelPosition.value.width}px`,
                                zIndex: 1000,
                            }}
                        >
                            {/* Action buttons */}
                            <div class="flex items-center gap-2 p-3 pb-2">
                                {/* Play button */}
                                <button
                                    class="flex items-center justify-center w-8 h-8 rounded-full bg-white hover:bg-white/90 transition-colors duration-150"
                                    onClick={(e) => {
                                        e.preventDefault();
                                        e.stopPropagation();
                                    }}
                                    aria-label="Reproducir"
                                >
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="black" stroke="none">
                                        <polygon points="5 3 19 12 5 21 5 3" />
                                    </svg>
                                </button>

                                {/* Add to list */}
                                <button
                                    class="flex items-center justify-center w-8 h-8 rounded-full border-2 border-white/50 hover:border-white text-white transition-all duration-150"
                                    onClick={(e) => {
                                        e.preventDefault();
                                        e.stopPropagation();
                                    }}
                                    aria-label="Agregar a mi lista"
                                >
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round">
                                        <line x1="12" y1="5" x2="12" y2="19" />
                                        <line x1="5" y1="12" x2="19" y2="12" />
                                    </svg>
                                </button>

                                {/* Like button */}
                                <button
                                    class="flex items-center justify-center w-8 h-8 rounded-full border-2 border-white/50 hover:border-white text-white transition-all duration-150"
                                    onClick={(e) => {
                                        e.preventDefault();
                                        e.stopPropagation();
                                    }}
                                    aria-label="Me gusta"
                                >
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
                                    </svg>
                                </button>

                                <div class="flex-1" />

                                {/* More info / chevron down */}
                                <button
                                    class="flex items-center justify-center w-8 h-8 rounded-full border-2 border-white/50 hover:border-white text-white transition-all duration-150"
                                    onClick={(e) => {
                                        e.preventDefault();
                                        e.stopPropagation();
                                    }}
                                    aria-label="Más información"
                                >
                                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                                        <polyline points="6 9 12 15 18 9" />
                                    </svg>
                                </button>
                            </div>

                            {/* Metadata */}
                            <div class="px-3 pb-2">
                                <div class="flex items-center gap-2 text-[11px] mb-1 flex-wrap">
                                    {props.item.rating && (
                                        <span class="text-green-400 font-semibold">{props.item.rating}</span>
                                    )}
                                    {props.item.year && <span class="text-white/60">{props.item.year}</span>}
                                    {props.item.duration && (
                                        <span class="text-white/60">
                                            {Math.floor(props.item.duration / 3600)}h {(Math.floor(props.item.duration / 60) % 60)}m
                                        </span>
                                    )}
                                </div>

                                {props.item.genres && props.item.genres.length > 0 && (
                                    <p class="text-[11px] text-white/50 line-clamp-1">
                                        {truncateGenres(props.item.genres)}
                                    </p>
                                )}
                            </div>
                        </div>
                    )}
                </Teleport>
            </div>
        );
    },
});
