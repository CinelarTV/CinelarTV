import { defineComponent, ref, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import { ajax } from '@/lib/Ajax';
import { useSiteSettings } from '@/app/services/site-settings';
import CIcon from '@/components/c-icon.vue';

interface LiveChannel {
    id: string;
    name: string;
    logo_url: string | null;
    stream_url: string;
    stream_format: string;
    current_program: {
        title: string;
        description: string | null;
    } | null;
}

export default defineComponent({
    name: 'LiveTvSection',
    setup() {
        const router = useRouter();
        const { siteSettings } = useSiteSettings();
        const channels = ref<LiveChannel[]>([]);
        const isLoading = ref(true);

        const isVisible = computed(() =>
            siteSettings?.enable_live_tv && channels.value.length > 0
        );

        const sectionTitle = computed(() =>
            siteSettings?.live_tv_section_title || 'Live TV'
        );

        async function fetchChannels() {
            try {
                const { data } = await ajax.get('/live_tv.json');
                channels.value = data.live_tv_channels || [];
            } catch (err) {
                console.error('Error fetching live TV channels:', err);
                channels.value = [];
            } finally {
                isLoading.value = false;
            }
        }

        function watchChannel(channelId: string) {
            router.push({ name: 'live_tv.watch', params: { id: channelId } });
        }

        function viewAll() {
            router.push({ name: 'live_tv.index' });
        }

        onMounted(() => {
            if (siteSettings?.enable_live_tv) {
                fetchChannels();
            }
        });

        return () => {
            if (!isVisible.value || isLoading.value) {
                return null;
            }

            return (
                <section class="py-6">
                    <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
                        {/* Section Header */}
                        <div class="mb-4 flex items-center justify-between">
                            <div class="flex items-center gap-2">
                                <div class="h-3 w-3 animate-pulse rounded-full bg-red-600"></div>
                                <h2 class="text-xl font-bold text-white">{sectionTitle.value}</h2>
                                <span class="rounded bg-red-600 px-2 py-0.5 text-xs font-semibold text-white">
                                    {channels.value.length}
                                </span>
                            </div>
                            <button
                                onClick={viewAll}
                                class="flex items-center gap-1 text-sm text-white/60 transition-colors hover:text-white"
                            >
                                Ver todo
                                <CIcon icon="chevron-right" size={16} />
                            </button>
                        </div>

                        {/* Channels Row */}
                        <div class="flex gap-4 overflow-x-auto pb-2 scrollbar-hide">
                            {channels.value.map((channel) => (
                                <button
                                    key={channel.id}
                                    onClick={() => watchChannel(channel.id)}
                                    class="group flex-shrink-0"
                                >
                                    {/* Channel Card */}
                                    <div class="relative w-32 overflow-hidden rounded-lg bg-white/5 transition-all hover:bg-white/10 hover:shadow-lg hover:shadow-black/50 group-hover:scale-105">
                                        {/* Channel Logo */}
                                        <div class="flex aspect-video items-center justify-center p-4">
                                            {channel.logo_url ? (
                                                <img
                                                    src={channel.logo_url}
                                                    alt={channel.name}
                                                    class="h-full w-full object-contain"
                                                    loading="lazy"
                                                />
                                            ) : (
                                                <CIcon icon="broadcast" size={32} class="text-white/30" />
                                            )}
                                        </div>

                                        {/* Live Badge */}
                                        <div class="absolute right-2 top-2 flex items-center gap-1 rounded bg-red-600 px-1.5 py-0.5 text-[10px] font-bold uppercase text-white">
                                            <div class="h-1 w-1 animate-pulse rounded-full bg-white"></div>
                                            LIVE
                                        </div>

                                        {/* Channel Name & Current Program */}
                                        <div class="p-2">
                                            <p class="truncate text-xs font-medium text-white">{channel.name}</p>
                                            {channel.current_program && (
                                                <p class="mt-0.5 line-clamp-1 text-[10px] text-white/50">
                                                    {channel.current_program.title}
                                                </p>
                                            )}
                                        </div>
                                    </div>
                                </button>
                            ))}
                        </div>
                    </div>
                </section>
            );
        };
    }
});
