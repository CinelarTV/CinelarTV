import { defineComponent, ref, onMounted, onBeforeUnmount, inject } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useHead } from 'unhead';
import RequireSignupModal from '../components/modals/require-signup.modal.vue';
import SubscriptionPaywallModal from '../components/modals/subscription-paywall.modal.vue';
import Content from '../app/models/Content';
import CButton from '../components/forms/c-button';
import CSpinner from '../components/c-spinner';
import EpisodesList from "@/components/content/EpisodesList";

export default defineComponent({
    name: 'ContentView',
    setup() {
        const currentUser = inject('currentUser');
        const $route = useRoute();
        const router = useRouter();
        const loading = ref(true);
        const contentData = ref<Content | null>(null);
        const showTrailer = ref(false);
        const activeSeason = ref<string | null>(null);
        const requireSignupModalRef = ref<any>(null);
        const subscriptionPaywallModalRef = ref<any>(null);
        const relatedContentScroll = ref<HTMLElement | null>(null);

        const onScroll = () => {
            document.body.classList.toggle('scrolled', window.scrollY > 120);
        };

        const getContent = async () => {
            try {
                const data = await Content.getById($route.params.id.toString());
                contentData.value = data;
                const seasons = ((data as any)?.seasons ?? []) as any[];
                if ((data as any)?.isTVShow && seasons.length > 0) {
                    activeSeason.value = String(seasons[0].id);
                }
                loading.value = false;
                if ((data as any)?.trailerUrl) {
                    await preloadTrailer((data as any).trailerUrl);
                    showTrailer.value = true;
                }
            } catch (error: any) {
                if (error.response?.status === 404) {
                    router.replace({ name: 'application.not-found' });
                }
            }
        };

        const openRequireSignupModal = () => {
            requireSignupModalRef.value?.setIsOpen(true);
        };

        const playContent = async () => {
            if (!currentUser) {
                openRequireSignupModal();
                return;
            }

            if (contentData.value?.premium && !(currentUser as any).is_subscribed) {
                subscriptionPaywallModalRef.value?.setIsOpen(true);
                return;
            }

            if (contentData.value?.isMovie) {
                router.push({ path: `/watch/${contentData.value.id}` }).catch(console.error);
            } else if (contentData.value?.continueWatching) {
                router.push({ path: `/watch/${contentData.value.id}/${contentData.value.continueWatching.episodeId}` }).catch(console.error);
            } else if (contentData.value?.seasons?.[0]?.episodes?.[0]) {
                router.push({ path: `/watch/${contentData.value.id}/${contentData.value.seasons[0].episodes[0].id}` }).catch(console.error);
            }
        };

        const playEpisode = (episodeId: string) => {
            if (!currentUser) {
                openRequireSignupModal();
                return;
            }

            if (!contentData.value?.available) {
                toast.error(t("content.not_available"));
                return;
            }

            // Find episode to check premium status
            const episode = contentData.value?.seasons?.flatMap(s => s.episodes).find(e => e.id === episodeId);
            if (episode?.premium && !(currentUser as any).is_subscribed) {
                subscriptionPaywallModalRef.value?.setIsOpen(true);
                return;
            }

            router.push(`/watch/${contentData.value?.id}/${episodeId}`);
        };

        const preloadTrailer = async (trailerSrc: string) => {
            const video = document.createElement('video');
            video.src = trailerSrc;
            video.load();
        };

        onMounted(async () => {
            await getContent();
            document.body.classList.add('content-route');
            window.addEventListener('scroll', onScroll);
            onScroll();

            const bannerWrapper = document.querySelector('.banner-wrapper') as HTMLElement;
            if (bannerWrapper) {
                const image = new window.Image();
                image.src = contentData.value?.banner || '';
                image.addEventListener('load', () => {
                    bannerWrapper.style.backgroundImage = `url(${image.src})`;
                    bannerWrapper.classList.add('banner-loaded');
                });
                image.addEventListener('error', () => {
                    bannerWrapper.style.backgroundImage = contentData.value?.cover
                        ? `url(${contentData.value.cover})`
                        : 'url(/assets/images/content_no_media.png)';
                    bannerWrapper.classList.add('banner-loaded');
                });
            }

            if (contentData.value) {
                useHead({
                    title: contentData.value.title,
                    meta: [{ name: 'description', content: contentData.value.description }]
                });
            }
        });

        onBeforeUnmount(() => {
            document.body.classList.remove('content-route');
            document.body.classList.remove('scrolled');
            window.removeEventListener('scroll', onScroll);
        });

        return () => (
            <div class="content-view">
                {loading.value ? (
                    <div class="content-view__loader">
                        <CSpinner />
                    </div>
                ) : (
                    (() => {
                        const content = contentData.value as any;
                        const seasons = (content?.seasons ?? []) as any[];
                        const relatedContent = (content?.relatedContent ?? []) as any[];

                        return (
                            <div
                                class="content-overview"
                                data-content-id={content?.id}
                                data-content-type={content?.isMovie ? 'movie' : 'tvshow'}
                            >
                                {/* Banner full-bleed */}
                                <div class="banner-wrapper">
                                    <div class="banner-wrapper__side-fade" />
                                    <div class="banner-wrapper__bottom-fade" />
                                </div>

                                {/* Detalles superpuestos */}
                                <div class="content-details">
                                    {(() => {
                                        const metaItems: any[] = [];

                                        if (content?.isNew) {
                                            metaItems.push(
                                                <span class="content-meta__badge content-meta__badge--new">Nuevo</span>
                                            );
                                        }

                                        if (content?.year) {
                                            metaItems.push(
                                                <span class="content-meta__text">{content.year}</span>
                                            );
                                        }

                                        if (content?.rating) {
                                            metaItems.push(
                                                <span class="content-meta__rating">
                                                    <span class="content-meta__star">★</span>
                                                    {content.rating}
                                                </span>
                                            );
                                        }

                                        if (content?.isTVShow && seasons.length > 0) {
                                            metaItems.push(
                                                <span class="content-meta__text">
                                                    {seasons.length} temporada{seasons.length !== 1 ? 's' : ''}
                                                </span>
                                            );
                                        }

                                        return (
                                            <div class="content-meta">
                                                {metaItems.map((item, index) => (
                                                    <span class="content-meta__entry" key={`meta-${index}`}>
                                                        {index > 0 && <span class="content-meta__dot" />}
                                                        {item}
                                                    </span>
                                                ))}
                                            </div>
                                        );
                                    })()}

                                    {/* Título */}
                                    <h1 class="content-title">{content?.title}</h1>

                                    {/* Descripción */}
                                    <p class="content-description">{content?.description}</p>

                                    {/* Acciones — se mantienen CButton con su icon prop */}
                                    <div class="content-actions">
                                        {contentData.value?.available ? (
                                            <>
                                                <CButton
                                                    icon={contentData.value?.premium && !(currentUser as any)?.is_subscribed ? 'lock' : 'play-circle'}
                                                    class={['content-actions__btn--primary', (contentData.value?.premium && !(currentUser as any)?.is_subscribed) ? 'premium-btn' : '']}
                                                    onClick={playContent}
                                                >
                                                    {content?.continueWatching ? 'Continuar viendo' : 'Reproducir'}
                                                </CButton>

                                            </>
                                        ) : (
                                            <p class="content-actions__unavailable">
                                                Este contenido no está disponible en este momento.
                                            </p>
                                        )}
                                    </div>

                                    {/* Episodios */}
                                    {content?.isTVShow && (
                                        seasons.length > 0 ? (
                                            <div class="content-episodes">
                                                <EpisodesList
                                                    seasons={seasons}
                                                    activeSeason={activeSeason.value || ''}
                                                    disabled={!contentData.value?.available}
                                                    onUpdate:activeSeason={val => activeSeason.value = val}
                                                    onPlayEpisode={playEpisode}
                                                />
                                            </div>
                                        ) : (
                                            <p class="content-episodes__empty">
                                                No hay temporadas disponibles para este programa.
                                            </p>
                                        )
                                    )}

                                    {/* Contenido relacionado */}
                                    {relatedContent.length > 0 && (
                                        <section class="content-related">
                                            <div class="content-related__head">
                                                <h3 class="content-related__title">Quizás te guste</h3>
                                                <p class="content-related__subtitle">Más historias con una vibra parecida.</p>
                                            </div>

                                            <div ref={relatedContentScroll} class="content-related__scroll">
                                                {relatedContent.map((relatedItem: any) => (
                                                    <router-link
                                                        key={relatedItem.id}
                                                        to={{ name: 'content.show', params: { id: relatedItem.id }, force: true }}
                                                        class="content-related__card"
                                                    >
                                                        <img
                                                            src={relatedItem.banner || relatedItem.cover}
                                                            alt={relatedItem.title}
                                                            class="content-related__card-img"
                                                            loading="lazy"
                                                        />
                                                        <div class="content-related__card-glow" />
                                                        <div class="content-related__card-overlay">
                                                            <div class="content-related__card-meta">
                                                                {relatedItem.year && (
                                                                    <span class="content-related__card-year">{relatedItem.year}</span>
                                                                )}
                                                                <span class="content-related__card-type">
                                                                    {relatedItem.isMovie ? 'Pelicula' : 'Serie'}
                                                                </span>
                                                            </div>
                                                            <span class="content-related__card-title">{relatedItem.title}</span>
                                                        </div>
                                                    </router-link>
                                                ))}
                                            </div>
                                        </section>
                                    )}
                                </div>

                                <RequireSignupModal
                                    ref={requireSignupModalRef}
                                    content-name={content?.title}
                                    onOpenSignupModal={() => { }}
                                />

                                <SubscriptionPaywallModal
                                    ref={subscriptionPaywallModalRef}
                                />
                            </div>
                        );
                    })()
                )}
            </div>
        );
    }
});