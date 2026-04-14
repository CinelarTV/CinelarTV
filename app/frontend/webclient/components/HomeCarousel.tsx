import { defineComponent, ref, onMounted, onBeforeUnmount, PropType, getCurrentInstance } from 'vue';
import CButton from './forms/c-button';
import CIconButton from './forms/c-icon-button.vue';
import CIcon from "./c-icon.vue";

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
    seasonCount?: number;
}

export default defineComponent({
    name: 'HomeCarousel',
    props: {
        items: {
            type: Array as PropType<BannerItem[]>,
            required: true,
        },
        onPlay: Function as PropType<(id: BannerItem['id']) => void>,
        onToggleCollection: Function as PropType<(id: BannerItem['id']) => void>,
        onShowInfo: Function as PropType<(id: BannerItem['id']) => void>,
        onToggleLike: Function as PropType<(id: BannerItem['id']) => void>,
        loading: {
            type: Boolean,
            default: false,
        },
        autoplay: {
            type: Boolean,
            default: true,
        },
        autoplayInterval: {
            type: Number,
            default: 7000,
        },
    },
    setup(props) {
        const trackRef = ref<HTMLElement | null>(null);
        const currentIndex = ref(0);
        const instance = getCurrentInstance();
        const isMobile = () => instance?.proxy?.$isMobile?.() ?? false;
        let rafId: number | null = null;
        let autoplayTimer: number | null = null;
        let resumeTimer: number | null = null;
        let isAutoplayPaused = false;

        const isDesktopViewport = () => window.matchMedia('(min-width: 1024px)').matches;

        const getTrackPaddingLeft = (track: HTMLElement) => {
            const styles = window.getComputedStyle(track);
            return Number.parseFloat(styles.paddingLeft || '0') || 0;
        };

        const getScrollLeftForIndex = (track: HTMLElement, index: number) => {
            const slide = track.children[index] as HTMLElement | undefined;
            if (!slide) return 0;

            const maxScroll = Math.max(0, track.scrollWidth - track.clientWidth);

            if (isDesktopViewport()) {
                const centeredLeft = slide.offsetLeft - ((track.clientWidth - slide.clientWidth) / 2);
                return Math.max(0, Math.min(centeredLeft, maxScroll));
            }

            const startLeft = slide.offsetLeft - getTrackPaddingLeft(track);
            return Math.max(0, Math.min(startLeft, maxScroll));
        };

        const scrollToIndex = (index: number) => {
            const track = trackRef.value;
            if (!track) return;

            const targetLeft = getScrollLeftForIndex(track, index);
            track.scrollTo({ left: targetLeft, behavior: 'smooth' });
            currentIndex.value = index;
        };

        const handleScroll = () => {
            const track = trackRef.value;
            if (!track) return;

            if (rafId !== null) {
                cancelAnimationFrame(rafId);
            }

            rafId = requestAnimationFrame(() => {
                let closestIndex = 0;
                let closestDistance = Number.POSITIVE_INFINITY;
                const trackRect = track.getBoundingClientRect();
                const trackCenter = trackRect.left + (trackRect.width / 2);
                const scrollLeft = track.scrollLeft;
                const paddingLeft = getTrackPaddingLeft(track);
                const snapStart = scrollLeft + paddingLeft;

                Array.from(track.children).forEach((child, index) => {
                    const slide = child as HTMLElement;
                    const slideRect = slide.getBoundingClientRect();
                    const slideCenter = slideRect.left + (slideRect.width / 2);
                    const distance = isDesktopViewport()
                        ? Math.abs(slideCenter - trackCenter)
                        : Math.abs(slide.offsetLeft - snapStart);
                    if (distance < closestDistance) {
                        closestDistance = distance;
                        closestIndex = index;
                    }
                });

                currentIndex.value = closestIndex;
            });
        };

        const scrollNext = () => scrollToIndex(Math.min(currentIndex.value + 1, props.items.length - 1));
        const scrollPrev = () => scrollToIndex(Math.max(currentIndex.value - 1, 0));

        const clearAutoplay = () => {
            if (autoplayTimer !== null) {
                window.clearInterval(autoplayTimer);
                autoplayTimer = null;
            }
        };

        const clearResumeTimer = () => {
            if (resumeTimer !== null) {
                window.clearTimeout(resumeTimer);
                resumeTimer = null;
            }
        };

        const startAutoplay = () => {
            clearAutoplay();
            if (!props.autoplay || props.items.length <= 1 || props.loading || isAutoplayPaused) return;

            autoplayTimer = window.setInterval(() => {
                const nextIndex = (currentIndex.value + 1) % props.items.length;
                scrollToIndex(nextIndex);
            }, props.autoplayInterval);
        };

        const pauseAutoplay = () => {
            isAutoplayPaused = true;
            clearAutoplay();
            clearResumeTimer();
        };

        const resumeAutoplay = (delay = 900) => {
            clearResumeTimer();
            resumeTimer = window.setTimeout(() => {
                isAutoplayPaused = false;
                startAutoplay();
            }, delay);
        };

        const handleKeyDown = (e: KeyboardEvent) => {
            if (e.key === 'ArrowRight') scrollNext();
            if (e.key === 'ArrowLeft') scrollPrev();
        };

        onMounted(() => {
            trackRef.value?.addEventListener('scroll', handleScroll, { passive: true });
            window.addEventListener('keydown', handleKeyDown);
            startAutoplay();
        });

        onBeforeUnmount(() => {
            trackRef.value?.removeEventListener('scroll', handleScroll);
            window.removeEventListener('keydown', handleKeyDown);
            if (rafId !== null) cancelAnimationFrame(rafId);
            clearAutoplay();
            clearResumeTimer();
        });

        return () => (
            <section
                id="home-carousel"
                class="home-carousel"
                onMouseenter={pauseAutoplay}
                onMouseleave={() => resumeAutoplay()}
                onFocusin={pauseAutoplay}
                onFocusout={() => resumeAutoplay(1200)}
                onTouchstart={pauseAutoplay}
                onTouchend={() => resumeAutoplay(1800)}
            >
                {/* Track con snap */}
                <div ref={trackRef} class="home-carousel__track">
                    {props.items.map((item, index) => (
                        <div
                            key={item.id}
                            class={[
                                'home-carousel__slide',
                                index === currentIndex.value ? 'home-carousel__slide--active' : '',
                                index === currentIndex.value + 1 ? 'home-carousel__slide--next' : '',
                            ]}
                        >
                            {/* Imagen de fondo */}
                            <img
                                src={item.banner}
                                alt={item.title}
                                class="home-carousel__bg"
                                loading={index === 0 ? 'eager' : 'lazy'}
                            />

                            {/* Gradientes */}
                            <div class="home-carousel__gradient-left" />
                            <div class="home-carousel__gradient-bottom" />

                            {/* Contenido */}
                            <div class="home-carousel__content">
                                {item.poster && (
                                    <div class="home-carousel__poster">
                                        <img src={item.poster} alt={item.title} />
                                    </div>
                                )}

                                <div class="home-carousel__info">
                                    <span class="home-carousel__eyebrow">
                                        <CIcon icon="star" class="home-carousel__eyebrow-icon" />
                                        Destacado
                                    </span>
                                    <h2 class="home-carousel__title" title={item.title}>{item.title}</h2>

                                    <div class="home-carousel__meta">
                                        {item.year && <span>{item.year}</span>}
                                        {item.rating && (
                                            <span class="home-carousel__meta-rating">{item.rating}</span>
                                        )}
                                        {item.genres && item.genres.length > 0 && (
                                            <>
                                                <span class="home-carousel__meta-dot">•</span>
                                                <span>{item.genres.slice(0, 3).join(' · ')}</span>
                                            </>
                                        )}
                                        {item.seasonCount && item.seasonCount > 1 && (
                                            <>
                                                <span class="home-carousel__meta-dot">•</span>
                                                <span>{item.seasonCount} temporadas</span>
                                            </>
                                        )}
                                    </div>

                                    <p class="home-carousel__description">{item.description}</p>

                                    <div class="home-carousel__actions">
                                        <CButton
                                            class="home-carousel__btn home-carousel__btn--primary"
                                            onClick={() => props.onPlay?.(item.id)}
                                        >
                                            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                                                <polygon points="5 3 19 12 5 21 5 3" />
                                            </svg>
                                            Reproducir
                                        </CButton>

                                        <CButton
                                            class="home-carousel__btn home-carousel__btn--secondary"
                                            onClick={() => props.onToggleCollection?.(item.id)}
                                        >
                                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                <rect x="3" y="3" width="18" height="18" rx="2" />
                                                <line x1="12" y1="8" x2="12" y2="16" />
                                                <line x1="8" y1="12" x2="16" y2="12" />
                                            </svg>
                                            Mi lista
                                        </CButton>

                                        <CIconButton
                                            icon="thumbs-up"
                                            class={['home-carousel__btn home-carousel__btn--icon', item.liked ? 'home-carousel__btn--liked' : '']}
                                            onClick={() => props.onToggleLike?.(item.id)}
                                        />
                                    </div>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>

                {/* Flechas — desktop */}
                {!isMobile() && props.items.length > 1 && (
                    <>
                        <button
                            class="home-carousel__arrow home-carousel__arrow--prev"
                            onClick={scrollPrev}
                            disabled={currentIndex.value === 0}
                            aria-label="Anterior"
                        >
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                                <polyline points="15 18 9 12 15 6" />
                            </svg>
                        </button>

                        <button
                            class="home-carousel__arrow home-carousel__arrow--next"
                            onClick={scrollNext}
                            disabled={currentIndex.value === props.items.length - 1}
                            aria-label="Siguiente"
                        >
                            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                                <polyline points="9 18 15 12 9 6" />
                            </svg>
                        </button>
                    </>
                )}

                {/* Indicadores */}
                {props.items.length > 1 && (
                    <div class="home-carousel__indicators">
                        {props.items.map((slideItem, index) => (
                            <button
                                key={`dot-${slideItem.id}`}
                                class={['home-carousel__dot', index === currentIndex.value ? 'home-carousel__dot--active' : '']}
                                onClick={() => scrollToIndex(index)}
                                aria-label={`Ir al slide ${index + 1}`}
                                aria-current={index === currentIndex.value ? 'true' : undefined}
                            />
                        ))}
                    </div>
                )}

                {/* Loading */}
                {props.loading && (
                    <div class="home-carousel__loading">
                        <div class="home-carousel__spinner" />
                    </div>
                )}
            </section>
        );
    },
});
