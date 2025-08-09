import { defineComponent, ref, computed, onMounted, onBeforeUnmount, PropType, watch, getCurrentInstance } from 'vue';
import CButton from "./forms/c-button";
import CIconButton from "./forms/c-icon-button.vue";
import { RouterLink } from "vue-router";

interface BannerItem {
    id: number | string;
    title: string;
    description: string;
    banner: string;
    liked?: boolean;
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
            default: 8000,
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
        const carouselContainer = ref<HTMLUListElement | null>(null);
        const currentIndex = ref(0);
        const isUserInteracting = ref(false);
        const autoScrollInterval = ref<any>(null);
        let scrollDebounceTimer: any = null;

        // Acceso a $isMobile
        const instance = getCurrentInstance();
        const isMobile = () => instance?.proxy?.$isMobile?.() ?? false;

        const itemsCount = computed(() => props.items.length);

        const startAutoScroll = () => {
            if (!props.autoScroll || autoScrollInterval.value || isUserInteracting.value || itemsCount.value <= 1) return;
            autoScrollInterval.value = setInterval(() => {
                if (!isUserInteracting.value) scrollToNextSlide();
            }, props.autoScrollDelay);
        };

        const stopAutoScroll = () => {
            if (autoScrollInterval.value) {
                clearInterval(autoScrollInterval.value);
                autoScrollInterval.value = null;
            }
        };

        const pauseAutoScroll = () => {
            isUserInteracting.value = true;
            stopAutoScroll();
        };

        const resumeAutoScroll = () => {
            isUserInteracting.value = false;
            setTimeout(startAutoScroll, 1000);
        };

        const scrollToSlide = (index: number) => {
            if (index < 0 || index >= itemsCount.value) return;
            pauseAutoScroll();
            const container = carouselContainer.value;
            if (!container) return;

            const slideWidth = container.offsetWidth;
            const scrollOffset = slideWidth * index;
            container.scrollTo({ left: scrollOffset, behavior: 'smooth' });
            currentIndex.value = index;
            resumeAutoScroll();
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
            const container = carouselContainer.value;
            if (!container) return;

            // Pausar auto-scroll al hacer scroll manual
            pauseAutoScroll();

            if (scrollDebounceTimer) clearTimeout(scrollDebounceTimer);
            scrollDebounceTimer = setTimeout(() => {
                const slideWidth = container.offsetWidth;
                const scrollOffset = container.scrollLeft;
                const newIndex = Math.round(scrollOffset / slideWidth);
                if (newIndex !== currentIndex.value && newIndex >= 0 && newIndex < itemsCount.value) {
                    currentIndex.value = newIndex;
                }
                // Reiniciar auto-scroll después de 1s sin scroll
                resumeAutoScroll();
            }, 1000);
        };

        onMounted(() => {
            if (props.autoScroll) startAutoScroll();
        });

        onBeforeUnmount(() => {
            stopAutoScroll();
            if (scrollDebounceTimer) clearTimeout(scrollDebounceTimer);
        });

        watch(() => props.items, () => {
            currentIndex.value = 0;
            stopAutoScroll();
            if (props.autoScroll) startAutoScroll();
        });

        // Render
        return () => (
            <section id="home-carousel" class="relative w-full">
                <div class="carousel-root relative flex flex-col items-center justify-center">
                    <ul
                        class={[
                            "carousel-ul flex overflow-x-auto snap-x snap-mandatory scrollbar-hide w-full",
                            isMobile() ? 'gap-0' : 'gap-4'
                        ]}
                        ref={carouselContainer}
                        onScroll={handleScroll}
                        onMouseenter={pauseAutoScroll}
                        onMouseleave={resumeAutoScroll}
                        role="region"
                        aria-label="Banner carousel"
                        style={{ scrollBehavior: 'smooth' }}
                    >
                        {props.items.map((item, index) => (
                            <li
                                key={item.id}
                                class={[
                                    'carousel-li snap-center flex-shrink-0 transition-all duration-300',
                                    index === currentIndex.value ? 'scale-100 opacity-100 z-20' : 'scale-95 opacity-80 z-10'
                                ]}
                                aria-label={`Banner ${index + 1}: ${item.title}`}
                                style={isMobile()
                                    ? { minWidth: '100vw', maxWidth: '100vw', aspectRatio: '16/10' }
                                    : { minWidth: '85vw', maxWidth: '1200px', aspectRatio: '21/9' }
                                }
                            >
                                <article class="prime-hero-card relative w-full h-full flex flex-col overflow-hidden rounded-lg shadow-xl bg-black">
                                    {/* Imagen de fondo */}
                                    <div class="absolute inset-0">
                                        <img
                                            class="w-full h-full object-cover"
                                            src={item.banner}
                                            alt={`Banner de ${item.title}`}
                                            loading={index === 0 ? "eager" : "lazy"}
                                        />
                                        <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-black/30 to-transparent" />
                                    </div>

                                    {/* Contenido */}
                                    <div class={[
                                        "relative z-20 flex flex-col justify-end h-full p-4",
                                        isMobile() ? 'text-center items-center' : 'text-left items-start max-w-2xl',
                                        !isMobile() && 'md:p-8 lg:p-12'
                                    ]}>
                                        <RouterLink
                                            to={`/contents/${item.id}`}
                                            class={[
                                                "font-bold text-white drop-shadow-lg mb-2 line-clamp-2",
                                                isMobile() ? 'text-xl' : 'text-2xl md:text-3xl lg:text-4xl'
                                            ]}>
                                            {item.title}
                                        </RouterLink>

                                        <p class={[
                                            "text-white/90 drop-shadow mb-4 line-clamp-3",
                                            isMobile() ? 'text-sm max-w-sm' : 'text-base md:text-lg max-w-lg'
                                        ]}>
                                            {item.description}
                                        </p>

                                        {/* Botones */}
                                        <div class={[
                                            "flex gap-3 w-full",
                                            isMobile() ? 'flex-col max-w-sm' : 'flex-row'
                                        ]}>
                                            <CButton
                                                class={[
                                                    "c-btn c-btn--primary flex items-center justify-center font-semibold rounded shadow-lg transition-all hover:scale-105",
                                                    isMobile() ? 'px-6 py-3 text-base' : 'px-6 py-2.5 text-sm md:px-8 md:py-3 md:text-base'
                                                ]}
                                                onClick={() => props.onPlay?.(item.id)}
                                            >
                                                <c-icon icon="play"
                                                    size={isMobile() ? 20 : 18} class="mr-2" />
                                                Ver ahora
                                            </CButton>

                                            <CButton
                                                class={[
                                                    "c-btn c-btn--secondary flex items-center justify-center font-semibold rounded shadow-lg transition-all hover:scale-105",
                                                    isMobile() ? 'px-6 py-3 text-base' : 'px-6 py-2.5 text-sm md:px-8 md:py-3 md:text-base'
                                                ]}
                                                onClick={() => props.onToggleCollection?.(item.id)}
                                            >
                                                <c-icon icon="plus" size={isMobile() ? 20 : 18} class="mr-2" />
                                                Mi colección
                                            </CButton>

                                            {!isMobile() && (
                                                <CIconButton
                                                    icon="thumbs-up"
                                                    class={[
                                                        "c-btn c-btn--ghost flex items-center justify-center rounded shadow-lg transition-all hover:scale-105",
                                                        "px-3 py-2.5 md:px-4 md:py-3",
                                                        item.liked ? '!text-blue-400' : 'text-white'
                                                    ]}
                                                    onClick={() => props.onToggleLike?.(item.id)}
                                                />
                                            )}
                                        </div>
                                    </div>
                                </article>
                            </li>
                        ))}
                    </ul>

                    {/* Indicadores */}
                    <div class="carousel-indicators flex items-center justify-center gap-2 mt-4 mb-2">
                        {props.items.map((item, index) => (
                            <button
                                key={`indicator-${item.id}`}
                                class={[
                                    'h-2 rounded-full transition-all duration-300 cursor-pointer',
                                    index === currentIndex.value
                                        ? 'bg-white w-8 md:w-12'
                                        : 'bg-white/40 w-2 hover:bg-white/60'
                                ]}
                                onClick={() => scrollToSlide(index)}
                                aria-label={`Ir al slide ${index + 1}`}
                            />
                        ))}
                    </div>

                    {/* Flechas de navegación - Solo desktop */}
                    {!isMobile() && itemsCount.value > 1 && (
                        <>
                            <button
                                class="carousel-arrow absolute left-4 top-1/2 -translate-y-1/2 z-30 bg-black/50 hover:bg-black/70 text-white rounded-full p-3 shadow-xl transition-all hover:scale-110 disabled:opacity-50 disabled:cursor-not-allowed"
                                onClick={scrollToPreviousSlide}
                                aria-label="Slide anterior"
                                disabled={currentIndex.value === 0}
                            >
                                <c-icon icon="chevron-left" size={24} />
                            </button>

                            <button
                                class="carousel-arrow absolute right-4 top-1/2 -translate-y-1/2 z-30 bg-black/50 hover:bg-black/70 text-white rounded-full p-3 shadow-xl transition-all hover:scale-110 disabled:opacity-50 disabled:cursor-not-allowed"
                                onClick={scrollToNextSlide}
                                aria-label="Siguiente slide"
                                disabled={currentIndex.value === itemsCount.value - 1}
                            >
                                <c-icon icon="chevron-right" size={24} />
                            </button>
                        </>
                    )}
                </div>

                {/* Loading state */}
                {props.loading && (
                    <div class="absolute inset-0 bg-black/50 flex items-center justify-center z-50">
                        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-white"></div>
                    </div>
                )}
            </section>
        );
    }
});