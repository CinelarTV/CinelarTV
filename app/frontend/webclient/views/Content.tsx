import { defineComponent, ref, onMounted, onBeforeUnmount, watch, inject } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useHead } from 'unhead';
import requireSignupModal from '../components/modals/require-signup.modal.vue';
import Content from '../app/models/Content';
import CButton from '../components/forms/c-button';

import ContentCard from '../components/content-card.vue';
import cSpinner from "../components/c-spinner";
import EpisodesList from "@/components/content/EpisodesList";

interface Episode {
    id: string;
    title: string;
    description: string;
    thumbnail: string;
}


interface RelatedContent {
    id: string;
    title: string;
    cover: string;
}



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

        const toggleSeason = (seasonId: string) => {
            if (activeSeason.value !== seasonId) {
                activeSeason.value = seasonId;
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

            console.log(`Playing content with ID: ${contentData.value?.id}`);
            console.log(`Navigated to /watch/${contentData.value.id}`);
            console.log(router)
            if (contentData.value?.isMovie) {
                router.push({
                    path: `/watch/${contentData.value.id}`,
                }).catch(console.error);
            } else if (contentData.value?.continueWatching) {
                router.push({
                    path: `/watch/${contentData.value.id}/${contentData.value.continueWatching.episodeId}`
                }).catch(console.error);
            } else if (contentData.value?.seasons?.[0]?.episodes?.[0]) {
                router.push({
                    path: `/watch/${contentData.value.id}/${contentData.value.seasons[0].episodes[0].id}`
                }).catch(console.error);
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
            // Banner background
            const bannerWrapper = document.querySelector('.banner-wrapper') as HTMLElement;
            const image = new window.Image();
            image.src = contentData.value?.banner || '';
            image.addEventListener('load', () => {
                bannerWrapper.style.backgroundImage = `url(${image.src})`;
                bannerWrapper.classList.add('banner-loaded');
            });
            image.addEventListener('error', () => {
                if (contentData.value?.cover) {
                    bannerWrapper.style.backgroundImage = `url(${contentData.value.cover})`;
                } else {
                    bannerWrapper.style.backgroundImage = 'url(/assets/images/content_no_media.png)';
                }
                bannerWrapper.classList.add('banner-loaded');
            });
            // SEO
            if (contentData.value) {
                useHead({
                    title: contentData.value.title,
                    meta: [
                        { name: 'description', content: contentData.value.description }
                    ]
                });
            }
        });

        // Scroll effect
        onMounted(() => {
            const onScroll = () => {
                if (window.scrollY > 120) {
                    document.body.classList.add('scrolled');
                } else {
                    document.body.classList.remove('scrolled');
                }
            };
            window.addEventListener('scroll', onScroll);
            onBeforeUnmount(() => window.removeEventListener('scroll', onScroll));
        });

        return () => (
            <div>
                {loading.value ? (
                    <div class="mt-4 text-center">
                        <cSpinner />
                    </div>
                ) : (
                    <div class="content-overview" data-content-id={contentData.value?.id} data-content-type={contentData.value?.isMovie ? 'movie' : 'tvshow'}>
                        <div class="banner-wrapper" />
                        <div class="content-details">
                            <div class="content-title">
                                <h1>{contentData.value?.title}</h1>
                            </div>
                            <div class="content-description">
                                <p>{contentData.value?.description}</p>
                            </div>
                            <div class="content-actions">
                                {contentData.value?.available ? (
                                    <CButton icon="play-circle" class="bg-blue-500 hover:bg-blue-600 text-white" onClick={playContent}>
                                        {contentData.value?.continueWatching ? 'Continuar viendo' : 'Reproducir'}
                                    </CButton>
                                ) : (
                                    <p><span class="text-red-500">Este contenido no está disponible en este momento.</span></p>
                                )}
                            </div>
                            {contentData.value?.isTVShow && (
                                contentData.value.seasons && contentData.value.seasons.length > 0 ? (
                                    <div class="relative">

                                        <div class="episodes-list">
                                            <EpisodesList
                                                seasons={contentData.value.seasons}
                                                activeSeason={activeSeason.value}
                                                onUpdate:activeSeason={val => activeSeason.value = val}
                                                onPlayEpisode={playEpisode}
                                            />

                                        </div>
                                    </div>
                                ) : (
                                    <p class="my-4 text-yellow-500">No hay temporadas disponibles para este programa.</p>
                                )
                            )}
                            <div class="related-content w-full">
                                <div class="text-2xl font-bold mb-4 text-white">Quizá te guste...</div>
                                <div class="related-content-horizontal overflow-x-auto flex gap-4 pb-2">
                                    {contentData.value?.relatedContent?.map(content => (
                                        <router-link to={{ name: 'content.show', params: { id: content.id }, force: true }} key={content.id} class="block min-w-[9rem] max-w-[9rem]">
                                            <div class="content-card flex flex-col items-center bg-[#23232a] rounded-lg shadow hover:bg-[#18181b] transition p-2">
                                                <div class="content-card__image w-32 h-48 flex-shrink-0 overflow-hidden rounded-md bg-gray-800 mb-2">
                                                    <img src={content.cover} alt="Cover Image" class="object-cover w-full h-full rounded-md" />
                                                </div>
                                                <div class="content-card__title text-base font-semibold text-white text-center truncate w-full">{content.title}</div>
                                            </div>
                                        </router-link>
                                    ))}
                                </div>
                            </div>
                        </div>
                        <requireSignupModal ref={requireSignupModalRef} content-name={contentData.value?.title} onOpenSignupModal={() => { }} />
                    </div>
                )}
            </div>
        );
    }
});
