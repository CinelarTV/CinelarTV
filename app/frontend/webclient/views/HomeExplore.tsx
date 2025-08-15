import { defineComponent, ref, computed, onMounted, onBeforeUnmount, inject, getCurrentInstance } from 'vue';
import { useRouter } from 'vue-router';
import { useHead } from 'unhead';
import { toast } from 'vue-sonner';
import { ajax } from '../lib/Ajax';
import ContentCard from '../components/content-card.vue';
import CIconButton from '../components/forms/c-icon-button.vue';
import HomeCarousel from '../components/HomeCarousel';
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
            <div id="home-explore">
                {/* Loading state */}
                {loading.value && (
                    <div class="mx-auto mt-4">
                        <c-spinner />
                    </div>
                )}
                {/* Main content */}
                {!loading.value && homepage.value && (
                    <div class="mx-auto mt-4">
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
                        {/* Content sections */}
                        <section id="main-content">
                            {contentCategories.value.map((category: any) => (
                                <div key={category.title}>
                                    <h3 class="text-2xl font-bold mt-8 mb-2 ml-6">{category.title}</h3>
                                    {category.content?.length ? (
                                        <div class="recyclerview">
                                            <ul>
                                                {category.content.map((item: any) => (
                                                    <ContentCard key={item.id} data={item} class="content-item" />
                                                ))}
                                            </ul>
                                        </div>
                                    ) : (
                                        <div class="ml-6 text-gray-500">No hay contenido disponible en esta categoría.</div>
                                    )}
                                </div>
                            ))}
                        </section>
                        <div class="flex justify-center items-center mt-4 py-8">
                            <c-icon icon="award" class="text-4xl mr-2" size="24" />
                            <p>Esto es todo por ahora. ¡Vuelve pronto para más contenido!</p>
                        </div>
                    </div>
                )}
                {/* Empty state */}
                {!loading.value && !homepage.value && (
                    <div class="flex justify-center items-center mt-8">
                        <p>No se pudo cargar el contenido. Intenta recargar la página.</p>
                    </div>
                )}

            </div>
        );
    },
});
