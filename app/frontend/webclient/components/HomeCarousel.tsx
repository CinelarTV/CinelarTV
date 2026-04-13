import { defineComponent, ref, onMounted, onBeforeUnmount, PropType, getCurrentInstance } from 'vue';
import CButton from './forms/c-button';
import CIconButton from './forms/c-icon-button.vue';

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
    },
    setup(props) {
        const trackRef = ref<HTMLElement | null>(null);
        const currentIndex = ref(0);
        const instance = getCurrentInstance();
        const isMobile = () => instance?.proxy?.$isMobile?.() ?? false;

        const scrollToIndex = (index: number) => {
            const track = trackRef.value;
            if (!track) return;
            const child = track.children[index] as HTMLElement;
            if (!child) return;
            track.scrollTo({ left: child.offsetLeft, behavior: 'smooth' });
            currentIndex.value = index;
        };

        const handleScroll = () => {
            const track = trackRef.value;
            if (!track) return;
            const scrollLeft = track.scrollLeft;
            const width = track.offsetWidth;
            currentIndex.value = Math.round(scrollLeft / width);
        };

        const scrollNext = () => scrollToIndex(Math.min(currentIndex.value + 1, props.items.length - 1));
        const scrollPrev = () => scrollToIndex(Math.max(currentIndex.value - 1, 0));

        const handleKeyDown = (e: KeyboardEvent) => {
            if (e.key === 'ArrowRight') scrollNext();
            if (e.key === 'ArrowLeft') scrollPrev();
        };

        onMounted(() => {
            trackRef.value?.addEventListener('scroll', handleScroll, { passive: true });
            window.addEventListener('keydown', handleKeyDown);
        });

        onBeforeUnmount(() => {
            trackRef.value?.removeEventListener('scroll', handleScroll);
            window.removeEventListener('keydown', handleKeyDown);
        });

        return () => (
            <section id="home-carousel" class="home-carousel">
                {/* Track con snap */}
                <div ref={trackRef} class="home-carousel__track">
                    {props.items.map((item, index) => (
                        <div key={item.id} class="home-carousel__slide">
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
                                    <h2 class="home-carousel__title">{item.title}</h2>

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
