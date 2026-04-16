import { defineComponent, ref, computed, onMounted, onBeforeUnmount, inject, getCurrentInstance } from 'vue';
import { useRouter } from 'vue-router';
import { useHead } from 'unhead';
import { toast } from 'vue-sonner';
import { ajax } from '../lib/Ajax';
import ContentCard from '../components/content-card.vue';
import ContentRow from '../components/content-row.vue';
import CIconButton from '../components/forms/c-icon-button.vue';
import HomeCarousel from '../components/HomeCarousel';
import LiveTvSection from '../components/LiveTvSection';
import PluginOutlet from "@/components/PluginOutlet";

export default defineComponent({
    name: 'HomeExplore',
    setup() {
        // Injected dependencies
        const SiteSettings = inject<any>('SiteSettings');
        const currentUser = inject<any>('currentUser');
        const homepageData = inject<any>('homepageData');
        const { $t } = getCurrentInstance()!.appContext.config.globalProperties;
        const router = useRouter();

        // State
        const homepage = ref<any>(null);
        const loading = ref(true);

        // Computed
        const bannerItems = computed(() => homepage.value?.banner_content || []);
        const contentCategories = computed(() => homepage.value?.content || []);
        const shouldShowCarousel = computed(() => SiteSettings?.enable_carousel && bannerItems.value.length > 0);

        // Head
        useHead({
            title: 'Explorar',
            meta: [
                {
                    name: 'description',
                    content: SiteSettings?.site?.description || 'Explora contenido',
                },
            ],
        });

        // Navigation methods
        const showInfo = (id: number | string) => {
            router.push({
                name: 'content.show',
                params: { id },
                meta: { transition: 'slide-left' },
            });
        };
        const playContent = async (id: number | string) => {
            console.log(`Playing content with ID: ${id}`);
            await router.push({
                path: `/watch/${id}`,
                meta: { transition: 'slide-left' },
            });
        };
        const toggleCollection = async (id: number | string) => {
            if (!currentUser) {
                toast.error($t('js.user.login_required'));
                return;
            }

            try {
                await ajax.post(`/users/collection/toggle.json`, { content_id: id });
                toast.success($t('js.user.added_to_collection'));
            } catch (error) {
                console.error('Error adding to collection:', error);
                toast.error($t('js.user.collection_error'));
            }
        };
        const toggleLike = async (id: number | string, fromBanner = false) => {
            if (!currentUser) {
                toast.error($t('js.user.login_required'));
                return;
            }
            try {
                const targetArray = fromBanner ? bannerItems.value : contentCategories.value.flatMap((cat: any) => cat.content || []);
                const content = targetArray.find((item: any) => item.id === id);
                if (!content) {
                    console.error(`Content with id ${id} not found`);
                    return;
                }
                const endpoint = content.liked ? 'unlike' : 'like';
                await ajax.post(`/contents/${id}/${endpoint}.json`);
                content.liked = !content.liked;
                toast.success(content.liked ? $t('js.user.added_to_favorites', { title: content.title }) : $t('js.user.removed_from_favorites', { title: content.title }));
            } catch (error) {
                console.error('Error toggling like:', error);
                toast.error($t('js.user.like_error'));
            }
        };

        // Data loading
        const loadHomepageData = async () => {
            try {
                loading.value = true;
                const response = await ajax.get('/explore.json');
                homepage.value = response.data;
            } catch (error) {
                console.error('Error loading homepage data:', error);
                toast.error('Error al cargar el contenido');
            } finally {
                loading.value = false;
            }
        };

        // Lifecycle
        onMounted(async () => {
            if (homepageData?.value) {
                homepage.value = homepageData.value;
                loading.value = false;
                if (homepageData.value) homepageData.value = null;
            } else {
                await loadHomepageData();
            }
        });

        // Render
        return () => (
            <div id="home-explore" class="min-h-screen">
                {/* Loading state */}
                {loading.value && (
                    <div class="flex items-center justify-center min-h-screen">
                        <div class="flex flex-col items-center gap-3">
                            <div class="animate-spin rounded-full h-12 w-12 border-2 border-white/30 border-t-[#00A8E1]"></div>
                            <p class="text-white/60 text-sm font-medium">Cargando...</p>
                        </div>
                    </div>
                )}

                {/* Main content */}
                {!loading.value && homepage.value && (
                    <div>
                        <PluginOutlet name="home:before-carousel" />

                        {/* Carousel section */}
                        {shouldShowCarousel.value && (
                            <HomeCarousel
                                items={bannerItems.value}
                                loading={loading.value}
                                onPlay={playContent}
                                onToggleCollection={toggleCollection}
                                onShowInfo={showInfo}
                                onToggleLike={id => toggleLike(id, true)}
                            />
                        )}

                        <PluginOutlet name="home:after-carousel" />

                        {/* Live TV Section */}
                        <LiveTvSection />

                        {/* Content sections */}
                        <section id="main-content" class="pb-8">
                            {contentCategories.value.map((category: any) => {
                                if (!category.content?.length) return null;

                                return (
                                    <div key={category.title}>
                                        {category.title === 'Continuar viendo' ? (
                                            <ContentRow
                                                title={category.title}
                                                items={category.content}
                                                itemType="landscape"
                                            />
                                        ) : (
                                            <ContentRow
                                                title={category.title}
                                                items={category.content}
                                                itemType="landscape"
                                            />
                                        )}
                                    </div>
                                );
                            })}
                        </section>

                        {/* End of content */}
                        <div class="flex justify-center items-center mt-8 py-12 text-white/40">
                            <div class="text-center">
                                <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" class="w-8 h-8 mx-auto mb-3 opacity-60">
                                    <path d="M6 9H4.5a2.5 2.5 0 0 1 0-5C7 4 6 9 6 9" />
                                    <path d="M18 9h1.5a2.5 2.5 0 0 0 0-5C17 4 18 9 18 9" />
                                    <path d="M4 22h16" />
                                    <path d="M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22" />
                                    <path d="M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22" />
                                    <path d="M18 2H6v7a6 6 0 0 0 12 0V2Z" />
                                </svg>
                                <p class="text-sm">Esto es todo por ahora. ¡Vuelve pronto para más contenido!</p>
                            </div>
                        </div>
                    </div>
                )}

                {/* Empty state */}
                {!loading.value && !homepage.value && (
                    <div class="flex items-center justify-center min-h-screen">
                        <div class="text-center text-white/60">
                            <p class="text-lg font-medium mb-2">No se pudo cargar el contenido</p>
                            <p class="text-sm">Intenta recargar la página.</p>
                        </div>
                    </div>
                )}
            </div>
        );
    },
});
