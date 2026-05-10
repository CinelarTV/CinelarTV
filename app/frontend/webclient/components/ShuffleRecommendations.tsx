import { defineComponent, ref, computed, onMounted, onBeforeUnmount, inject, getCurrentInstance } from 'vue';
import { useRouter } from 'vue-router';
import { ajax } from '../lib/Ajax';
import CButton from './forms/c-button';
import CIcon from './c-icon.vue';
import { MediaPlayer } from 'vidstack';
import 'vidstack/bundle';

interface ShuffleItem {
    id: number | string;
    title: string;
    description: string;
    banner: string;
    trailer_url: string;
    content_type: string;
    year?: number;
    liked?: boolean;
}

export default defineComponent({
    name: 'ShuffleRecommendations',
    setup() {
        const SiteSettings = inject<any>('SiteSettings');
        const router = useRouter();
        const { $t } = getCurrentInstance()!.appContext.config.globalProperties;

        const recommendations = ref<ShuffleItem[]>([]);
        const currentIndex = ref(0);
        const isLoading = ref(false);
        const isTransitioning = ref(false);
        const showTrailer = ref(false);
        const videoPlayer = ref<MediaPlayer | null>(null);
        const isModalOpen = ref(false);

        const isVisible = computed(() => SiteSettings?.enable_shuffle_recommendations);
        const currentItem = computed(() => recommendations.value[currentIndex.value] || null);

        const fetchRecommendations = async () => {
            try {
                isLoading.value = true;
                const response = await ajax.get('/shuffle_recommendations.json');
                recommendations.value = response.data || [];
                if (recommendations.value.length > 0) {
                    currentIndex.value = 0;
                }
            } catch (error) {
                console.error('Error fetching shuffle recommendations:', error);
            } finally {
                isLoading.value = false;
            }
        };

        const shuffle = () => {
            if (recommendations.value.length === 0) return;

            isTransitioning.value = true;
            showTrailer.value = false;

            setTimeout(() => {
                currentIndex.value = (currentIndex.value + 1) % recommendations.value.length;
                isTransitioning.value = false;
                // Auto-play trailer for new item
                showTrailer.value = true;
            }, 300);
        };

        const playContent = async () => {
            if (!currentItem.value) return;
            await router.push({
                path: `/watch/${currentItem.value.id}`,
                meta: { transition: 'slide-left' },
            });
        };

        const showInfo = () => {
            if (!currentItem.value) return;
            router.push({
                name: 'content.show',
                params: { id: currentItem.value.id },
                meta: { transition: 'slide-left' },
            });
        };

        const toggleTrailer = () => {
            if (!currentItem.value?.trailer_url) return;
            showTrailer.value = !showTrailer.value;
        };

        const openModal = () => {
            isModalOpen.value = true;
            showTrailer.value = true; // Auto-play trailer when modal opens
            document.body.style.overflow = 'hidden';
        };

        const closeModal = () => {
            isModalOpen.value = false;
            showTrailer.value = false;
            document.body.style.overflow = '';
        };

        onMounted(() => {
            if (isVisible.value) {
                fetchRecommendations();
            }
        });

        onBeforeUnmount(() => {
            document.body.style.overflow = '';
        });

        return () => {
            if (!isVisible.value || isLoading.value) return null;
            if (recommendations.value.length === 0) return null;

            const item = currentItem.value;
            if (!item) return null;

            return (
                <>
                    {/* Preview Card */}
                    <section class="shuffle-recommendations py-8">
                        <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
                            <div
                                class="shuffle-recommendations__preview cursor-pointer relative overflow-hidden rounded-2xl bg-gradient-to-br from-gray-900 to-black hover:scale-[1.02] transition-transform duration-300"
                                onClick={openModal}
                            >
                                {/* Background image with overlay */}
                                <div class="shuffle-recommendations__background absolute inset-0">
                                    <img
                                        src={item.banner}
                                        alt={item.title}
                                        class="h-full w-full object-cover opacity-30"
                                    />
                                    <div class="absolute inset-0 bg-gradient-to-t from-black via-black/60 to-transparent" />
                                </div>

                                {/* Content */}
                                <div class="relative z-20 p-8 md:p-12 flex flex-col items-center justify-center text-center min-h-[200px]">
                                    <div class="rounded-full bg-purple-600/30 p-4 mb-4 animate-pulse">
                                        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="text-purple-400">
                                            <path d="M16 3h5v5" />
                                            <path d="M4 20L21 3" />
                                            <path d="M21 16v5h-5" />
                                            <path d="M15 15l6 6" />
                                            <path d="M4 4l5 5" />
                                        </svg>
                                    </div>
                                    <h2 class="text-2xl md:text-3xl font-bold text-white mb-2">
                                        {$t('js.shuffle_recommendations.title')}
                                    </h2>
                                    <p class="text-white/70 mb-4 max-w-md">
                                        {$t('js.shuffle_recommendations.description')}
                                    </p>
                                    <CButton
                                        class="bg-white text-black hover:bg-white/90 px-8 py-3 rounded-xl font-semibold"
                                    >
                                        <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor" class="mr-2 inline">
                                            <polygon points="5 3 19 12 5 21 5 3" />
                                        </svg>
                                        {$t('js.shuffle_recommendations.play_something')}
                                    </CButton>
                                </div>
                            </div>
                        </div>
                    </section>

                    {/* Fullscreen Modal */}
                    {isModalOpen.value && (
                        <div class="fixed inset-0 z-50">
                            {/* Backdrop with fade transition */}
                            <div
                                class={[
                                    'absolute inset-0 bg-black',
                                    'transition-opacity duration-500 ease-out',
                                    isModalOpen.value ? 'opacity-100' : 'opacity-0'
                                ]}
                                onClick={closeModal}
                            />

                            {/* Modal Content with scale and fade transition */}
                            <div class={[
                                'relative z-10 w-full h-screen',
                                'transition-all duration-500 ease-out transform',
                                isModalOpen.value ? 'opacity-100 scale-100' : 'opacity-0 scale-95'
                            ]}>
                                <div class="h-full relative">
                                    {/* Background image with overlay */}
                                    <div class="absolute inset-0">
                                        <img
                                            src={item.banner}
                                            alt={item.title}
                                            class="h-full w-full object-cover"
                                        />
                                        <div class="absolute inset-0 bg-gradient-to-t from-black/80 via-black/40 to-transparent" />
                                    </div>

                                    {/* Exit button - top left */}
                                    <button
                                        onClick={closeModal}
                                        class="absolute top-6 left-6 z-30 bg-white/10 hover:bg-white/20 backdrop-blur-sm px-4 py-2 rounded text-white text-sm font-medium transition-colors"
                                    >
                                        Exit
                                    </button>

                                    {/* Trailer video overlay with vidstack */}
                                    {showTrailer.value ? (
                                        <div class="absolute inset-0 z-20">
                                            <media-player
                                                key={`trailer-${item.id}`}
                                                class="h-full w-full"
                                                autoplay
                                                controls
                                            >
                                                <media-provider>
                                                    <media-poster
                                                        class="absolute inset-0 block h-full w-full object-cover"
                                                        src={item.banner}
                                                        alt={item.title}
                                                    />
                                                    <source src={item.trailer_url} type="video/youtube" />
                                                </media-provider>
                                            </media-player>
                                        </div>
                                    ) : null}

                                    {/* Navigation arrows */}
                                    <button
                                        onClick={shuffle}
                                        class="absolute left-4 top-1/2 -translate-y-1/2 z-30 bg-white/10 hover:bg-white/20 backdrop-blur-sm p-3 rounded-full text-white transition-colors"
                                    >
                                        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                            <path d="M15 18l-6-6 6-6" />
                                        </svg>
                                    </button>
                                    <button
                                        onClick={shuffle}
                                        class="absolute right-4 top-1/2 -translate-y-1/2 z-30 bg-white/10 hover:bg-white/20 backdrop-blur-sm p-3 rounded-full text-white transition-colors"
                                    >
                                        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                            <path d="M9 18l6-6-6-6" />
                                        </svg>
                                    </button>

                                    {/* Content info - bottom left with small text */}
                                    <div class="absolute bottom-8 left-8 z-20 max-w-md">
                                        <div class={[
                                            'transition-all duration-500',
                                            isTransitioning.value ? 'opacity-0 translate-y-4' : 'opacity-100 translate-y-0'
                                        ]}>
                                            <div class="mb-2 flex items-center gap-2 text-white/80 text-sm font-medium">
                                                {item.content_type && (
                                                    <span class="uppercase tracking-wider">
                                                        {item.content_type === 'TVSHOW' ? 'SERIES' : 'MOVIE'}
                                                    </span>
                                                )}
                                                {item.year && <span>•</span>}
                                                {item.year && <span>{item.year}</span>}
                                            </div>
                                            <h3 class="text-2xl font-bold text-white mb-2">
                                                {item.title}
                                            </h3>
                                            <p class="text-sm text-white/70 line-clamp-2 mb-4">
                                                {item.description}
                                            </p>
                                        </div>
                                    </div>

                                    {/* Play Something Else button - center right */}
                                    <div class="absolute bottom-8 right-8 z-20">
                                        <CButton
                                            class="bg-white text-black hover:bg-white/90 px-6 py-3 rounded-lg text-sm font-semibold"
                                            onClick={shuffle}
                                        >
                                            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" class="mr-2 inline">
                                                <polygon points="5 3 19 12 5 21 5 3" />
                                            </svg>
                                            Play Something Else
                                        </CButton>
                                    </div>

                                    {/* Action buttons overlay */}
                                    <div class="absolute bottom-8 left-1/2 -translate-x-1/2 z-20 flex items-center gap-3">
                                        <CButton
                                            class="bg-white text-black hover:bg-white/90 px-6 py-3 rounded-lg text-sm font-semibold"
                                            onClick={playContent}
                                        >
                                            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" class="mr-2 inline">
                                                <polygon points="5 3 19 12 5 21 5 3" />
                                            </svg>
                                            Play
                                        </CButton>
                                        {item.trailer_url && (
                                            <CButton
                                                class="bg-white/10 text-white hover:bg-white/20 backdrop-blur-sm px-4 py-3 rounded-lg text-sm font-semibold"
                                                onClick={toggleTrailer}
                                            >
                                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="mr-2 inline">
                                                    <polygon points="5 3 19 12 5 21 5 3" />
                                                </svg>
                                                {showTrailer.value ? 'Hide' : 'Trailer'}
                                            </CButton>
                                        )}
                                        <CButton
                                            class="bg-white/10 text-white hover:bg-white/20 backdrop-blur-sm p-3 rounded-lg"
                                            onClick={showInfo}
                                            aria-label="More Info"
                                        >
                                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                <circle cx="12" cy="12" r="10" />
                                                <line x1="12" y1="16" x2="12" y2="12" />
                                                <line x1="12" y1="8" x2="12.01" y2="8" />
                                            </svg>
                                        </CButton>
                                    </div>
                                </div>
                            </div>
                        </div>
                    )}
                </>
            );
        };
    },
});
