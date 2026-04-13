import { defineComponent, ref, onMounted, onBeforeUnmount, inject } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useHead } from 'unhead';
import requireSignupModal from '../components/modals/require-signup.modal.vue';
import Content from '../app/models/Content';
import CButton from '../components/forms/c-button';
import cSpinner from "../components/c-spinner";
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
        const relatedContentScroll = ref<HTMLElement | null>(null);

        const getContent = async () => {
            try {
                const data = await Content.getById($route.params.id.toString());
                contentData.value = data;
                if (data?.isTVShow && data.seasons?.length > 0) {
                    activeSeason.value = String(data.seasons[0].id);
                }
                loading.value = false;
                if (data?.trailerUrl) {
                    await preloadTrailer(data.trailerUrl);
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

        onBeforeUnmount(() => {
            document.body.classList.remove('content-route');
        });

        const playContent = async () => {
            if (!currentUser) {
                openRequireSignupModal();
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

            const bannerWrapper = document.querySelector('.banner-wrapper') as HTMLElement;
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

            if (contentData.value) {
                useHead({
                    title: contentData.value.title,
                    meta: [{ name: 'description', content: contentData.value.description }]
                });
            }
        });

        onMounted(() => {
            const onScroll = () => {
                document.body.classList.toggle('scrolled', window.scrollY > 120);
            };
            window.addEventListener('scroll', onScroll);
            onBeforeUnmount(() => window.removeEventListener('scroll', onScroll));
        });

        return () => (
            <div class="content-view">
                {loading.value ? (
                    <div class="content-view__loader">
                        <cSpinner />
                    </div>
                ) : (
                    <div
                        class="content-overview"
                        data-content-id={contentData.value?.id}
                        data-content-type={contentData.value?.isMovie ? 'movie' : 'tvshow'}
                    >
                        {/* Banner full-bleed */}
                        <div class="banner-wrapper">
                            <div class="banner-wrapper__side-fade" />
                            <div class="banner-wrapper__bottom-fade" />
                        </div>

                        {/* Detalles superpuestos */}
                        <div class="content-details">

                            {/* Metadata */}
                            <div class="content-meta">
                                {contentData.value?.isNew && (
                                    <span class="content-meta__badge content-meta__badge--new">Nuevo</span>
                                )}
                                {contentData.value?.year && (
                                    <>
                                        <span class="content-meta__dot" />
                                        <span class="content-meta__text">{contentData.value.year}</span>
                                    </>
                                )}
                                {contentData.value?.rating && (
                                    <>
                                        <span class="content-meta__dot" />
                                        <span class="content-meta__rating">
                                            <span class="content-meta__star">★</span>
                                            {contentData.value.rating}
                                        </span>
                                    </>
                                )}
                                {contentData.value?.isTVShow && contentData.value.seasons?.length > 0 && (
                                    <>
                                        <span class="content-meta__dot" />
                                        <span class="content-meta__text">
                                            {contentData.value.seasons.length} temporada{contentData.value.seasons.length !== 1 ? 's' : ''}
                                        </span>
                                    </>
                                )}
                            </div>

                            {/* Título */}
                            <h1 class="content-title">{contentData.value?.title}</h1>

                            {/* Descripción */}
                            <p class="content-description">{contentData.value?.description}</p>

                            {/* Acciones — se mantienen CButton con su icon prop */}
                            <div class="content-actions">
                                {contentData.value?.available ? (
                                    <>
                                        <CButton
                                            icon="play-circle"
                                            class="content-actions__btn--primary"
                                            onClick={playContent}
                                        >
                                            {contentData.value?.continueWatching ? 'Continuar viendo' : 'Reproducir'}
                                        </CButton>

                                    </>
                                ) : (
                                    <p class="content-actions__unavailable">
                                        Este contenido no está disponible en este momento.
                                    </p>
                                )}
                            </div>

                            {/* Episodios */}
                            {contentData.value?.isTVShow && (
                                contentData.value.seasons?.length > 0 ? (
                                    <div class="content-episodes">
                                        <EpisodesList
                                            seasons={contentData.value.seasons}
                                            activeSeason={activeSeason.value}
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
                            {contentData.value?.relatedContent?.length > 0 && (
                                <div class="content-related">
                                    <h3 class="content-related__title">Quizás te guste...</h3>
                                    <div ref={relatedContentScroll} class="content-related__scroll">
                                        {contentData.value.relatedContent.map(content => (
                                            <router-link
                                                key={content.id}
                                                to={{ name: 'content.show', params: { id: content.id }, force: true }}
                                                class="content-related__card"
                                            >
                                                <img
                                                    src={content.banner || content.cover}
                                                    alt={content.title}
                                                    class="content-related__card-img"
                                                    loading="lazy"
                                                />
                                                <div class="content-related__card-overlay">
                                                    <span class="content-related__card-title">{content.title}</span>
                                                </div>
                                            </router-link>
                                        ))}
                                    </div>
                                </div>
                            )}
                        </div>

                        <requireSignupModal
                            ref={requireSignupModalRef}
                            content-name={contentData.value?.title}
                            onOpenSignupModal={() => { }}
                        />
                    </div>
                )}
            </div>
        );
    }
});