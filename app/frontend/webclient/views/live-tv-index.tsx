import { defineComponent, ref, onMounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import { ajax } from '@/lib/Ajax';
import { useSiteSettings } from '@/app/services/site-settings';
import { useHead } from 'unhead';
import { toast } from 'vue-sonner';

import SiteHeader from '@/components/SiteHeader';
import CSpinner from '@/components/c-spinner';
import CIcon from '@/components/c-icon.vue';

interface LiveChannel {
    id: string;
    name: string;
    description: string | null;
    logo_url: string | null;
    stream_url: string;
    stream_format: string;
    is_active: boolean;
    xmltv_channel_id: string | null;
    current_program: {
        id: string;
        title: string;
        description: string | null;
        start_time: string;
        end_time: string;
        icon_url: string | null;
        category: string | null;
    } | null;
    upcoming_programs: Array<{
        id: string;
        title: string;
        description: string | null;
        start_time: string;
        end_time: string;
    }>;
}

export default defineComponent({
    name: 'LiveTvIndex',
    setup() {
        const { siteSettings } = useSiteSettings();
        const router = useRouter();
        const channels = ref<LiveChannel[]>([]);
        const isLoading = ref(true);
        const error = ref<string | null>(null);

        const sectionTitle = computed(() =>
            siteSettings?.live_tv_section_title || 'Live TV'
        );

        useHead({ title: sectionTitle.value });

        async function fetchChannels() {
            try {
                isLoading.value = true;
                error.value = null;
                const { data } = await ajax.get('/live_tv.json');
                channels.value = data.live_tv_channels || [];
            } catch (err: any) {
                const errorMsg = err?.response?.data?.error || 'Error al cargar los canales en vivo.';
                error.value = errorMsg;
                toast.error(errorMsg);
            } finally {
                isLoading.value = false;
            }
        }

        function watchChannel(channelId: string) {
            router.push({ name: 'live_tv.watch', params: { id: channelId } });
        }

        function viewGuide(channelId: string) {
            router.push({ name: 'live_tv.guide', params: { id: channelId } });
        }

        onMounted(fetchChannels);

        return () => {
            if (isLoading.value) {
                return (
                    <div class="min-h-screen bg-[#0a0a0a]">
                        <SiteHeader />
                        <div class="flex h-[60vh] items-center justify-center">
                            <CSpinner class="w-12 h-12 text-white" />
                        </div>
                    </div>
                );
            }

            if (error.value && channels.value.length === 0) {
                return (
                    <div class="min-h-screen bg-[#0a0a0a]">
                        <SiteHeader />
                        <div class="flex h-[60vh] flex-col items-center justify-center gap-4">
                            <CIcon icon="broadcast-off" size={48} class="text-white/30" />
                            <p class="text-lg text-white/60">{error.value}</p>
                            <button
                                onClick={() => router.push('/')}
                                class="rounded bg-white/10 px-4 py-2 text-sm text-white hover:bg-white/20"
                            >
                                Volver al inicio
                            </button>
                        </div>
                    </div>
                );
            }

            return (
                <div class="min-h-screen bg-[#0a0a0a]">
                    <SiteHeader />
                    <div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
                        <div class="mb-8 flex items-center gap-3">
                            <div class="flex items-center gap-2">
                                <div class="h-3 w-3 animate-pulse rounded-full bg-red-600"></div>
                                <CIcon icon="broadcast" size={24} class="text-red-500" />
                            </div>
                            <h1 class="text-3xl font-bold text-white">{sectionTitle.value}</h1>
                        </div>

                        {channels.value.length === 0 ? (
                            <div class="flex flex-col items-center justify-center py-16 text-center">
                                <CIcon icon="broadcast-off" size={64} class="mb-4 text-white/20" />
                                <h2 class="mb-2 text-xl font-semibold text-white">No hay canales disponibles</h2>
                                <p class="text-white/60">
                                    No se han configurado canales de televisión en vivo.
                                </p>
                            </div>
                        ) : (
                            <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                                {channels.value.map((channel) => (
                                    <div
                                        key={channel.id}
                                        class="group relative cursor-pointer overflow-hidden rounded-lg bg-white/5 transition-all hover:bg-white/10 hover:shadow-lg hover:shadow-black/50"
                                        onClick={() => watchChannel(channel.id)}
                                    >
                                        {/* Channel Logo & Banner */}
                                        <div class="relative aspect-video overflow-hidden bg-gradient-to-br from-white/10 to-white/5">
                                            {channel.logo_url ? (
                                                <img
                                                    src={channel.logo_url}
                                                    alt={channel.name}
                                                    class="h-full w-full object-contain p-6 transition-transform group-hover:scale-105"
                                                    loading="lazy"
                                                />
                                            ) : (
                                                <div class="flex h-full items-center justify-center">
                                                    <CIcon icon="broadcast" size={48} class="text-white/30" />
                                                </div>
                                            )}

                                            {/* Live Badge */}
                                            <div class="absolute right-3 top-3 flex items-center gap-1.5 rounded bg-red-600 px-2.5 py-1 text-xs font-bold uppercase text-white">
                                                <div class="h-1.5 w-1.5 animate-pulse rounded-full bg-white"></div>
                                                LIVE
                                            </div>
                                        </div>

                                        {/* Channel Info */}
                                        <div class="p-4">
                                            <h3 class="mb-1 text-lg font-semibold text-white">{channel.name}</h3>

                                            {/* Current Program */}
                                            {channel.current_program ? (
                                                <div class="space-y-1">
                                                    <p class="text-sm font-medium text-white/80">
                                                        <span class="text-red-400">Ahora:</span>{' '}
                                                        {channel.current_program.title}
                                                    </p>
                                                    {channel.current_program.description && (
                                                        <p class="line-clamp-2 text-xs text-white/50">
                                                            {channel.current_program.description}
                                                        </p>
                                                    )}
                                                    <div class="mt-2 flex items-center gap-2 text-xs text-white/40">
                                                        <CIcon icon="clock" size={12} />
                                                        <span>
                                                            {new Date(channel.current_program.start_time).toLocaleTimeString('es-ES', {
                                                                hour: '2-digit',
                                                                minute: '2-digit'
                                                            })}
                                                            {' - '}
                                                            {new Date(channel.current_program.end_time).toLocaleTimeString('es-ES', {
                                                                hour: '2-digit',
                                                                minute: '2-digit'
                                                            })}
                                                        </span>
                                                    </div>
                                                </div>
                                            ) : (
                                                <p class="text-sm text-white/40">Sin programación actual</p>
                                            )}

                                            {/* Action Buttons */}
                                            <div class="mt-4 flex gap-2">
                                                <button
                                                    onClick={(e) => {
                                                        e.stopPropagation();
                                                        watchChannel(channel.id);
                                                    }}
                                                    class="flex flex-1 items-center justify-center gap-1.5 rounded bg-red-600 px-3 py-2 text-sm font-medium text-white transition-colors hover:bg-red-700"
                                                >
                                                    <CIcon icon="play" size={14} />
                                                    Ver ahora
                                                </button>
                                                {channel.upcoming_programs.length > 0 && (
                                                    <button
                                                        onClick={(e) => {
                                                            e.stopPropagation();
                                                            viewGuide(channel.id);
                                                        }}
                                                        class="rounded bg-white/10 px-3 py-2 text-sm font-medium text-white/80 transition-colors hover:bg-white/20 hover:text-white"
                                                    >
                                                        <CIcon icon="calendar" size={14} />
                                                    </button>
                                                )}
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>
                </div>
            );
        };
    }
});
