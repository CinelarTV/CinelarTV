import { defineComponent, ref, computed, onMounted, onBeforeUnmount, PropType, getCurrentInstance, watch, Transition } from 'vue';
import CButton from "./forms/c-button";
import CIconButton from "./forms/c-icon-button.vue";

interface BannerItem {
    id: number | string;
    title: string;
    description: string;
    banner: string;
    poster?: string;
    liked?: boolean;
    year?: number;
    rating?: string;
    genres?: string[];
    isPrime?: boolean;
    seasonCount?: number;
}

declare module 'vue' {
    interface ComponentCustomProperties {
        $isMobile: () => boolean;
    }
}

export default defineComponent({
    name: 'HomeCarousel',
    props: {
        items: {
            type: Array as PropType<BannerItem[]>,
            required: true,
        },
        autoScroll: {
            type: Boolean,
            default: true,
        },
        autoScrollDelay: {
            type: Number,
            default: 10000,
        },
        loading: {
            type: Boolean,
            default: false,
        },
        onPlay: Function as PropType<(id: BannerItem['id']) => void>,
        onToggleCollection: Function as PropType<(id: BannerItem['id']) => void>,
        onShowInfo: Function as PropType<(id: BannerItem['id']) => void>,
        onToggleLike: Function as PropType<(id: BannerItem['id']) => void>,
    },
    setup(props) {
        const currentIndex = ref(0);
        const isUserInteracting = ref(false);
        const autoScrollInterval = ref<any>(null);
        const touchStartX = ref(0);
        const touchEndX = ref(0);
        let scrollDebounceTimer: any = null;
        let progressInterval: any = null;
        const progress = ref(0);

        const instance = getCurrentInstance();
        const isMobile = () => instance?.proxy?.$isMobile?.() ?? false;

        const itemsCount = computed(() => props.items.length);
        const currentItem = computed(() => props.items[currentIndex.value]);

        const startAutoScroll = () => {
            if (!props.autoScroll || autoScrollInterval.value || isUserInteracting.value || itemsCount.value <= 1) return;

            progress.value = 0;
            const step = 100 / (props.autoScrollDelay / 50);

            progressInterval = setInterval(() => {
                progress.value = Math.min(progress.value + step, 100);
            }, 50);

            autoScrollInterval.value = setInterval(() => {
                if (!isUserInteracting.value) scrollToNextSlide();
            }, props.autoScrollDelay);
        };

        const stopAutoScroll = () => {
            if (autoScrollInterval.value) {
                clearInterval(autoScrollInterval.value);
                autoScrollInterval.value = null;
            }
            if (progressInterval) {
                clearInterval(progressInterval);
                progressInterval = null;
            }
        };

        const pauseAutoScroll = () => {
            isUserInteracting.value = true;
            stopAutoScroll();
        };

        const resumeAutoScroll = () => {
            isUserInteracting.value = false;
            progress.value = 0;
            setTimeout(startAutoScroll, 2000);
        };

        const scrollToSlide = (index: number) => {
            if (index < 0 || index >= itemsCount.value || index === currentIndex.value) return;

            pauseAutoScroll();
            currentIndex.value = index;
        };

        const scrollToNextSlide = () => {
            const nextIndex = (currentIndex.value + 1) % itemsCount.value;
            scrollToSlide(nextIndex);
        };

        const scrollToPreviousSlide = () => {
            const prevIndex = (currentIndex.value - 1 + itemsCount.value) % itemsCount.value;
            scrollToSlide(prevIndex);
        };

        const handleScroll = () => {
            pauseAutoScroll();
            if (scrollDebounceTimer) clearTimeout(scrollDebounceTimer);
            scrollDebounceTimer = setTimeout(() => {
                resumeAutoScroll();
            }, 500);
        };

        const handleTouchStart = (e: TouchEvent) => {
            touchStartX.value = e.touches[0].clientX;
            pauseAutoScroll();
        };

        const handleTouchMove = (e: TouchEvent) => {
            touchEndX.value = e.touches[0].clientX;
        };

        const handleTouchEnd = () => {
            const diff = touchStartX.value - touchEndX.value;
            const threshold = 50;

            if (Math.abs(diff) > threshold) {
                if (diff > 0) {
                    scrollToNextSlide();
                } else {
                    scrollToPreviousSlide();
                }
            }

            resumeAutoScroll();
        };

        const handleKeyDown = (e: KeyboardEvent) => {
            if (e.key === 'ArrowLeft') {
                scrollToPreviousSlide();
            } else if (e.key === 'ArrowRight') {
                scrollToNextSlide();
            }
        };

        onMounted(() => {
            if (props.autoScroll) startAutoScroll();
            window.addEventListener('keydown', handleKeyDown);
        });

        onBeforeUnmount(() => {
            stopAutoScroll();
            if (scrollDebounceTimer) clearTimeout(scrollDebounceTimer);
            window.removeEventListener('keydown', handleKeyDown);
        });

        watch(() => props.items, () => {
            currentIndex.value = 0;
            stopAutoScroll();
            if (props.autoScroll) startAutoScroll();
        });

        const renderSlideContent = (item: BannerItem) => {
            if (!item) return null;

            return (
                <div class="relative z-10 h-full">
                    <div class="flex h-full px-4 sm:px-6 md:px-8 lg:px-12 xl:px-16">
                        <div class="flex-1 flex items-center gap-6 md:gap-8 lg:gap-10 max-w-4xl">
                            {item.poster && (
                                <div class="hidden sm:block flex-shrink-0 w-32 md:w-40 lg:w-48 transform -translate-y-2">
                                    <div class="relative aspect-[2/3] overflow-hidden rounded-lg shadow-2xl ring-1 ring-white/10">
                                        <img src={item.poster} alt={item.title} class="w-full h-full object-cover" loading="lazy" />
                                        {item.isPrime !== false && (
                                            <div class="absolute top-2 left-2 bg-[#00A8E1] px-2 py-0.5 text-[10px] font-bold text-white rounded">
                                                PRIME
                                            </div>
                                        )}
                                    </div>
                                </div>
                            )}

                            <div class="flex-1 min-w-0">
                                <h2 class="text-2xl sm:text-3xl md:text-4xl lg:text-5xl xl:text-6xl font-bold text-white mb-3 md:mb-4 drop-shadow-2xl leading-tight max-w-2xl">
                                    {item.title}
                                </h2>

                                <div class="flex flex-wrap items-center gap-2 md:gap-3 mb-4 md:mb-5">
                                    {item.isPrime !== false && (
                                        <span class="sm:hidden bg-[#00A8E1] px-2 py-0.5 text-xs font-bold text-white rounded">
                                            PRIME
                                        </span>
                                    )}
                                    {item.year && <span class="text-sm md:text-base text-white/80">{item.year}</span>}
                                    {item.rating && (
                                        <span class="px-2 py-0.5 text-xs md:text-sm font-semibold text-white border border-white/40 rounded">
                                            {item.rating}
                                        </span>
                                    )}
                                    {(item.year || item.rating) && item.genres?.length && <span class="text-white/60">•</span>}
                                    {item.genres && item.genres.length > 0 && (
                                        <span class="text-sm md:text-base text-white/80 line-clamp-1">
                                            {item.genres.slice(0, 3).join(' • ')}
                                        </span>
                                    )}
                                    {item.seasonCount && item.seasonCount > 1 && (
                                        <>
                                            <span class="text-white/60">•</span>
                                            <span class="text-sm md:text-base text-white/80">
                                                {item.seasonCount} Temporada{item.seasonCount > 1 ? 's' : ''}
                                            </span>
                                        </>
                                    )}
                                </div>

                                <p class="text-sm md:text-base lg:text-lg text-white/90 mb-6 md:mb-8 line-clamp-3 max-w-xl drop-shadow-lg leading-relaxed">
                                    {item.description}
                                </p>

                                <div class="flex flex-wrap items-center gap-3 md:gap-4">
                                    <CButton
                                        class="flex items-center gap-2 px-6 py-3 md:px-7 md:py-3.5 bg-white text-black font-bold rounded-md hover:bg-white/90 transition-all duration-200 hover:scale-105 shadow-2xl"
                                        onClick={() => props.onPlay?.(item.id)}
                                    >
                                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="currentColor" class="w-5 h-5 md:w-6 md:h-6">
                                            <polygon points="5 3 19 12 5 21 5 3" />
                                        </svg>
                                        <span class="text-sm md:text-base">Reproducir</span>
                                    </CButton>

                                    <CButton
                                        class="flex items-center gap-2 px-6 py-3 md:px-7 md:py-3.5 bg-white/20 backdrop-blur-md text-white font-semibold rounded-md border border-white/30 hover:bg-white/30 transition-all duration-200 hover:scale-105 shadow-xl"
                                        onClick={() => props.onToggleCollection?.(item.id)}
                                    >
                                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="w-5 h-5 md:w-6 md:h-6">
                                            <rect x="3" y="3" width="18" height="18" rx="2" ry="2" />
                                            <line x1="12" y1="8" x2="12" y2="16" />
                                            <line x1="8" y1="12" x2="16" y2="12" />
                                        </svg>
                                        <span class="text-sm md:text-base">Mi lista</span>
                                    </CButton>

                                    <CIconButton
                                        icon="thumbs-up"
                                        class={[
                                            "flex items-center justify-center w-11 h-11 md:w-12 md:h-12 bg-white/20 backdrop-blur-md text-white rounded-md border border-white/30 hover:bg-white/30 transition-all duration-200 hover:scale-110 shadow-xl",
                                            item.liked ? '!text-[#00A8E1] !border-[#00A8E1]/50' : ''
                                        ]}
                                        onClick={() => props.onToggleLike?.(item.id)}
                                    />
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            );
        };

        return () => {
            const item = currentItem.value;
            if (!item) return null;

            return (
                <section id="home-carousel" class="relative w-full h-[50vh] sm:h-[55vh] md:h-[65vh] lg:h-[75vh] overflow-hidden">
                    {/* Vue Transition for crossfade */}
                    <Transition name="hero-fade" mode="in-out" appear>
                        <div key={item.id} class="absolute inset-0">
                            <img src={item.banner} alt={item.title} class="w-full h-full object-cover" style={{ objectPosition: 'center 20%' }} loading={currentIndex.value === 0 ? "eager" : "lazy"} />
                            <div class="absolute inset-0 bg-gradient-to-r from-black/90 via-black/50 to-transparent" />
                            <div class="absolute inset-0 bg-gradient-to-t from-black via-black/60 to-transparent" />
                            <div class="absolute bottom-0 left-0 right-0 h-1/2 bg-gradient-to-t from-black/80 to-transparent" />
                        </div>
                    </Transition>

                    {/* Content with Transition */}
                    <Transition name="hero-content" mode="in-out" appear>
                        <div key={`content-${item.id}`} class="relative z-10 h-full">
                            {renderSlideContent(item)}
                        </div>
                    </Transition>

                    {/* Navigation Arrows - Desktop */}
                    {!isMobile() && itemsCount.value > 1 && (
                        <>
                            <button
                                class="absolute left-3 md:left-6 top-1/2 -translate-y-1/2 z-50 flex items-center justify-center w-10 h-10 md:w-12 md:h-12 bg-black/50 backdrop-blur-md text-white rounded-full border border-white/20 hover:bg-black/70 hover:scale-110 transition-all duration-200 disabled:opacity-30 disabled:cursor-not-allowed disabled:hover:scale-100"
                                onClick={scrollToPreviousSlide}
                                disabled={currentIndex.value === 0}
                                aria-label="Previous slide"
                            >
                                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="w-5 h-5 md:w-6 md:h-6">
                                    <polyline points="15 18 9 12 15 6" />
                                </svg>
                            </button>

                            <button
                                class="absolute right-3 md:right-6 top-1/2 -translate-y-1/2 z-50 flex items-center justify-center w-10 h-10 md:w-12 md:h-12 bg-black/50 backdrop-blur-md text-white rounded-full border border-white/20 hover:bg-black/70 hover:scale-110 transition-all duration-200 disabled:opacity-30 disabled:cursor-not-allowed disabled:hover:scale-100"
                                onClick={scrollToNextSlide}
                                disabled={currentIndex.value === itemsCount.value - 1}
                                aria-label="Next slide"
                            >
                                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" class="w-5 h-5 md:w-6 md:h-6">
                                    <polyline points="9 18 15 12 9 6" />
                                </svg>
                            </button>
                        </>
                    )}

                    {/* Progress Indicators - Bottom */}
                    {itemsCount.value > 1 && (
                        <div class="absolute bottom-4 md:bottom-6 left-1/2 -translate-x-1/2 z-50 flex items-center gap-2">
                            {props.items.map((slideItem, index) => (
                                <button
                                    key={`indicator-${slideItem.id}`}
                                    class={[
                                        'rounded-full transition-all duration-300 cursor-pointer',
                                        index === currentIndex.value
                                            ? 'bg-white h-1.5 w-8 md:w-10'
                                            : 'bg-white/40 h-1.5 w-1.5 md:w-2 hover:bg-white/60'
                                    ]}
                                    onClick={() => scrollToSlide(index)}
                                    aria-label={`Go to slide ${index + 1}`}
                                />
                            ))}
                        </div>
                    )}

                    {/* Auto-scroll Progress Bar - Top */}
                    {props.autoScroll && itemsCount.value > 1 && (
                        <div class="absolute top-0 left-0 right-0 z-50 h-0.5 bg-black/30">
                            <div
                                class="h-full bg-[#00A8E1]/80 transition-all duration-100 ease-linear"
                                style={{ width: `${progress.value}%` }}
                            />
                        </div>
                    )}

                    {/* Loading State */}
                    {props.loading && (
                        <div class="absolute inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50">
                            <div class="flex flex-col items-center gap-3">
                                <div class="animate-spin rounded-full h-12 w-12 border-2 border-white/30 border-t-[#00A8E1]"></div>
                                <p class="text-white/80 text-sm font-medium">Cargando...</p>
                            </div>
                        </div>
                    )}
                </section>
            );
        };
    }
});
